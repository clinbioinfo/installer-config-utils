package InstallerConfig::Manager;

use Moose;
use Cwd;
use File::Path;
use FindBin;
use File::Basename;
use Term::ANSIColor;

use InstallerConfig::Logger;
use InstallerConfig::File::XML::Parser;
use InstallerConfig::File::Writer::Factory;

use constant TRUE  => 1;
use constant FALSE => 0;

use constant DEFAULT_VERBOSE => TRUE;

use constant DEFAULT_TEST_MODE => TRUE;

use constant MAX_ATTEMPT_COUNT => 2;

use constant MAX_ATTEMPT_MESSAGE => 'Please contact the administrator.';

use constant DEFAULT_USERNAME => getlogin || getpwuid($<) || $ENV{USER} || "sundaramj";

use constant DEFAULT_OUTDIR => '/tmp/' . DEFAULT_USERNAME . '/' . File::Basename::basename($0) . '/' . time();

use constant DEFAULT_INDIR => File::Spec->rel2abs(cwd());

use constant DEFAULT_OUTPUT_FILE_TYPE => 'text';

## Singleton support
my $instance;

has 'verbose' => (
    is       => 'rw',
    isa      => 'Bool',
    writer   => 'setVerbose',
    reader   => 'getVerbose',
    required => FALSE,
    default  => DEFAULT_VERBOSE
    );

has 'test_mode' => (
    is       => 'rw',
    isa      => 'Bool',
    writer   => 'setTestMode',
    reader   => 'getTestMode',
    required => FALSE,
    default  => DEFAULT_TEST_MODE
    );

has 'outdir' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setOutdir',
    reader   => 'getOutdir',
    required => FALSE,
    default  => DEFAULT_OUTDIR
    );

has 'indir' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setIndir',
    reader   => 'getIndir',
    required => FALSE,
    default  => DEFAULT_INDIR
    );

has 'infile' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setInfile',
    reader   => 'getInfile',
    required => FALSE
    );

has 'outfile' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setOutfile',
    reader   => 'getOutfile',
    required => FALSE
    );

has 'report_file' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setReportFile',
    reader   => 'getReportFile',
    required => FALSE
    );

has 'output_file_type' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setOutputFileType',
    reader   => 'getOutputFileType',
    required => FALSE,
    default  => DEFAULT_OUTPUT_FILE_TYPE
    );

sub getInstance {

    if (!defined($instance)){

        $instance = new InstallerConfig::Manager(@_);

        if (!defined($instance)){

            confess "Could not instantiate InstallerConfig::Manager";
        }
    }
    return $instance;
}

sub BUILD {

    my $self = shift;

    $self->_initLogger(@_);

    $self->_initParser(@_);

    $self->_initWriter(@_);

    $self->{_logger}->info("Instantiated ". __PACKAGE__);
}

sub _initLogger {

    my $self = shift;

    my $logger = Log::Log4perl->get_logger(__PACKAGE__);

    if (!defined($logger)){
        confess "logger was not defined";
    }

    $self->{_logger} = $logger;
}

sub _initParser {

    my $self = shift;

    my $parser = InstallerConfig::File::XML::Parser::getInstance(@_);

    if (!defined($parser)){
        $self->{_logger}->logconfess("Could not instantiate InstallerConfig::File::XML::Parser");
    }

    $self->{_parser} = $parser;
}

sub _initWriterFactory {

    my $self = shift;

    my $factory = InstallerConfig::File::Writer::Factory::getInstance(@_);

    if (!defined($factory)){
        $self->{_logger}->logconfess("Could not instantiate InstallerConfig::File::Writer::Factory");
    }


    $factory->setType($self->getOutputFileType);

    $self->{_writer_factory} = $factory;
}

sub _initWriter {

    my $self = shift;

    $self->_initWriterFactory(@_);

    my $writer = $self->{_writer_factory}->create(@_);

    if (!defined($writer)){
        $self->{_logger}->logconfess("Could not instantiate InstallerConfig::File::Writer");
    }

    my $outfile = $self->getOutfile();
    
    if (defined($outfile)){
        $writer->setOutfile($outfile);
    }

    $self->{_writer} = $writer;
}

sub run {

    my $self = shift;

    my $prompt_record_list = $self->{_parser}->getPromptRecordList();
    if (!defined($prompt_record_list)){
        $self->{_logger}->logconfess("prompt_record_list was not defined");
    }

    $self->{_prompt_ctr} = 0;

    $self->{_prompt_count} = scalar(@{$prompt_record_list});

    foreach my $record (@{$prompt_record_list}){
            
        $self->_prompt_user($record);
    }

    $self->{_logger}->info("Executed '$self->{_prompt_ctr}' prompts");


    $self->{_writer}->writeFile($prompt_record_list);
}

sub _prompt_user {

    my $self = shift;
    my ($record) = @_;

    $self->{_prompt_ctr}++;

    my $desc = $record->getDesc();

    my $prompt = $record->getPrompt();
    if (!defined($prompt)){
        $self->{_logger}->logconfess("prompt was not defined for record : " . Dumper $record);
    }    

    my $example_values_list;
    
    if ($record->hasExampleValues()){
        $example_values_list = $record->getExampleValueList();
    }

    my $acceptable_values_list;
    if ($record->hasAcceptableValues()){
        $acceptable_values_list = $record->getAcceptableValueList();
    }

    $self->{_attempt_ctr} = 0;

    my $answer;

    my $options_lookup = {};

    while (1){

        printBrightBlueBanner("Prompt $self->{_prompt_ctr} of $self->{_prompt_count}");

        if (defined($desc)){
            print "\nDescription:\n\n$desc\n";
        }
        
        
        if ($record->hasExampleValues()){
            print "\nExample values:\n";
            print join("\n", @{$example_values_list}) ."\n";
        }

        if ($record->hasAcceptableValues()){
    
            print "\nAcceptable values:\n";
    
            my $option_ctr = 0;
    
            foreach my $acceptable_value (@{$acceptable_values_list}){
    
                $option_ctr++;
    
                print $option_ctr . '. ' . $acceptable_value . "\n";
    
                $options_lookup->{$option_ctr} = $acceptable_value;    
            }
        }

        print "\n$prompt :";

        $answer = <STDIN>;

        chomp $answer;

        $answer =~ s|^\s+||; ## remove leading whitespace
        $answer =~ s|\s+$||; ## remove trailing whitespace


        if ($record->hasAcceptableValues()){

            $answer =~ s|\.+$||;  ## remove trailing periods

            if (exists $options_lookup->{$answer}){

                $record->setAnswer($options_lookup->{$answer});

                $self->{_logger}->info("User answered '$options_lookup->{$answer}' for prompt '$prompt'");

                last;
            }
            else {

                $self->_wrong_answer_handler($prompt);                

                printBoldRed("Please select one of the options. Please try again.");
            }
        }
        else {
            if ((defined($answer)) && ($answer ne '')){

                $record->setAnswer($answer);

                $self->{_logger}->info("User answered '$answer' for prompt '$prompt'");

                last;
            }
            else {

                $self->_wrong_answer_handler($prompt);

                printBoldRed("Please provide an answer. Please try again.");

            }
        }
    }
}


sub _wrong_answer_handler {

    my $self = shift;
    my ($prompt) = @_;

    $self->{_attempt_ctr}++;
    
    if ($self->{_attempt_ctr} > MAX_ATTEMPT_COUNT){
    
        printBoldRed(MAX_ATTEMPT_MESSAGE);
        print "Tell the administrator you could not answer the question '$prompt'\n";
            
        exit(1);
    }
}


sub _execute_cmd {

    my $self = shift;
    my ($cmd) = @_;
    
    my @results;
 
    $self->{_logger}->info("About to execute '$cmd'");
    
    eval {
    	@results = qx($cmd);
    };

    if ($?){
    	$self->{_logger}->logconfess("Encountered some error while attempting to execute '$cmd' : $! $@");
    }


    chomp @results;

    return \@results;
}


sub printBoldRed {

    my ($msg) = @_;
    print color 'bold red';
    print $msg . "\n";
    print color 'reset';
}

sub printBoldRedBanner {

    my ($msg) = @_;

    printBoldRed("\n****************************************************************************");
    printBoldRed("*");
    printBoldRed("* $msg");
    printBoldRed("*");
    printBoldRed("****************************************************************************");
}

sub printYellow {

    my ($msg) = @_;
    print color 'yellow';
    print $msg . "\n";
    print color 'reset';
}

sub printGreen {

    my ($msg) = @_;
    print color 'green';
    print $msg . "\n";
    print color 'reset';
}

sub printGreenBanner {

    my ($msg) = @_;

    printGreen("\n****************************************************************************");
    printGreen("*");
    printGreen("* $msg");
    printGreen("*");
    printGreen("****************************************************************************");
}

sub printBrightBlue {

    my ($msg) = @_;
    print color 'bright_blue';
    print  $msg . "\n";
    print color 'reset';
}

sub printBrightBlueBanner {

    my ($msg) = @_;

    printBrightBlue("\n****************************************************************************");
    printBrightBlue("*");
    printBrightBlue("* $msg");
    printBrightBlue("*");
    printBrightBlue("****************************************************************************");
}

no Moose;
__PACKAGE__->meta->make_immutable;

__END__


=head1 NAME

 InstallerConfig::Manager
 

=head1 VERSION

 1.0

=head1 SYNOPSIS

 use InstallerConfig::Manager;
 my $manager = InstallerConfig::Manager::getInstance();
 $manager->run();

=head1 AUTHOR

 Jaideep Sundaram

 Copyright Jaideep Sundaram

=head1 METHODS

=over 4

=cut
