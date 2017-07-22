package InstallerConfig::Prompt::Record;

use Moose;

use constant TRUE  => 1;

use constant FALSE => 0;

use constant DEFAULT_IS_PRIVATE => TRUE;

use constant DEFAULT_SEPARATOR => '=';

has 'prompt' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setPrompt',
    reader   => 'getPrompt',
    required => FALSE
    );

has 'desc' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setDesc',
    reader   => 'getDesc',
    required => FALSE
    );

has 'answer' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setAnswer',
    reader   => 'getAnswer',
    required => FALSE
    );

has 'parameter_name' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setParameterName',
    reader   => 'getParameterName',
    required => FALSE
    );

has 'separator' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setSeparator',
    reader   => 'getSeparator',
    required => FALSE,
    default  => DEFAULT_SEPARATOR
    );


sub BUILD {

    my $self = shift;

    $self->_initLogger(@_);

}

sub _initLogger {

    my $self = shift;

    my $logger = Log::Log4perl->get_logger(__PACKAGE__);
    if (!defined($logger)){
        confess "logger was not defined";
    }

    $self->{_logger} = $logger;
}


sub hasAcceptableValues {

    my $self = shift;
    
    if ((exists $self->{_acceptable_value_list}) &&
        (defined($self->{_acceptable_value_list})) &&
        scalar(@{$self->{_acceptable_value_list}}) > 0){
        return TRUE;
    }

    return FALSE;
}

sub addAcceptableValue {

    my $self = shift;
    my ($value) = @_;

    if (!defined($value)){
        $self->{_logger}->logconfess("value was not defined");
    }

    push(@{$self->{_acceptable_value_list}}, $value);

}

sub getAcceptableValueList {

    my $self = shift;
    
    return $self->{_acceptable_value_list};
}

sub hasExampleValues {

    my $self = shift;
    
    if ((exists $self->{_example_value_list}) &&
        (defined($self->{_example_value_list})) &&
        scalar(@{$self->{_example_value_list}}) > 0){
        return TRUE;
    }

    return FALSE;
}

sub addExampleValue {

    my $self = shift;
    my ($value) = @_;

    if (!defined($value)){
        $self->{_logger}->logconfess("value was not defined");
    }

    push(@{$self->{_example_value_list}}, $value);

}

sub getExampleValueList {

    my $self = shift;
    
    return $self->{_example_value_list};
}

no Moose;
__PACKAGE__->meta->make_immutable;


__END__


=head1 NAME

 InstallerConfig::Prompt::Record
 Module for encapsulating representation of a data member

=head1 VERSION

 1.0

=head1 SYNOPSIS

 use InstallerConfig::Prompt::Record;
 my $record = new InstallerConfig::Prompt::Record(
     name => 'numberOfPizzaSlices, 
     data_type => 'int', 
    );
 

=head1 AUTHOR

 Jaideep Sundaram

 Copyright Jaideep Sundaram

=head1 METHODS

=over 4

=cut