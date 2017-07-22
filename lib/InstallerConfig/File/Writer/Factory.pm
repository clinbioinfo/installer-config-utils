package InstallerConfig::File::Writer::Factory;

use Moose;

use InstallerConfig::File::Text::Writer;

use constant TRUE  => 1;
use constant FALSE => 0;

use constant DEFAULT_TYPE => 'text';

## Singleton support
my $instance;


has 'type' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setType',
    reader   => 'getType',
    required => FALSE,
    default  => DEFAULT_TYPE
);

sub getInstance {

    if (!defined($instance)){

        $instance = new InstallerConfig::File::Writer::Factory(@_);

        if (!defined($instance)){

            confess "Could not instantiate InstallerConfig::File::Writer::Factory";
        }
    }
    return $instance;
}

sub BUILD {

    my $self = shift;

    $self->_initLogger(@_);

    $self->{_logger}->info("Instantiated " . __PACKAGE__);
}

sub _initLogger {

    my $self = shift;

    my $logger = Log::Log4perl->get_logger(__PACKAGE__);
    if (!defined($logger)){
        confess "logger was not defined";
    }

    $self->{_logger} = $logger;
}

sub _getType {

    my $self = shift;
    my (%args) = @_;

    my $type = $self->getType();

    if (!defined($type)){

        if (( exists $args{type}) && ( defined $args{type})){
            $type = $args{type};
        }
        elsif (( exists $self->{_type}) && ( defined $self->{_type})){
            $type = $self->{_type};
        }
        else {
            $type = DEFAULT_TYPE;
            $self->{_logger}->warn("type was not defined and therefore was set to '$type'");
        }

        $self->setType($type);
    }

    return $type;
}

sub create {

    my $self = shift;

    my $type  = $self->getType();
    if (!defined($type)){
        $self->{_logger}->logconfess("type was not defined");
    }

    if (lc($type) eq 'text'){

        my $writer = InstallerConfig::File::Text::Writer::getInstance(@_);
        if (!defined($writer)){
            confess "Could not instantiate InstallerConfig::File::Text::Writer";
        }

        return $writer;
    }
    else {
        confess "type '$type' is not currently supported";
    }
}


no Moose;
__PACKAGE__->meta->make_immutable;

__END__

=head1 NAME

 InstallerConfig::File::Writer::Factory

 A module factory for creating Helper instances.

=head1 VERSION

 1.0

=head1 SYNOPSIS

 use InstallerConfig::File::Writer::Factory;
 my $factory = InstallerConfig::File::Writer::Factory::getIntance(type => $type);
 my $writer = $factory->create();

=head1 AUTHOR

 Jaideep Sundaram

 Copyright Jaideep Sundaram

=head1 METHODS

=over 4

=cut