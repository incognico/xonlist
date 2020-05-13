# ABSTRACT: Template::AutoFilter toolkit engine for Dancer2

package Dancer2::Template::TemplateAutoFilter;
$Dancer2::Template::TemplateAutoFilter::VERSION = '0.300003';
use Moo;
use Carp qw<croak>;
use Dancer2::Core::Types;
use Dancer2::FileUtils qw<path>;
use Scalar::Util ();
use Template::AutoFilter;

with 'Dancer2::Core::Role::Template';

has '+engine' => ( isa => InstanceOf ['Template'], );

sub _build_engine {
    my $self      = shift;
    my $charset   = $self->charset;
    my %tt_config = (
        ANYCASE  => 1,
        ABSOLUTE => 1,
        length($charset) ? ( ENCODING => $charset ) : (),
        %{ $self->config },
    );

    my $start_tag = $self->config->{'start_tag'};
    my $stop_tag = $self->config->{'stop_tag'} || $self->config->{end_tag};
    $tt_config{'START_TAG'} = $start_tag
      if defined $start_tag && $start_tag ne '[%';
    $tt_config{'END_TAG'} = $stop_tag
      if defined $stop_tag && $stop_tag ne '%]';

    Scalar::Util::weaken( my $ttt = $self );
    my $include_path = $self->config->{include_path};
    $tt_config{'INCLUDE_PATH'} ||= [
        ( defined $include_path ? $include_path : () ),
        sub { [ $ttt->views ] },
    ];

    my $tt = Template::AutoFilter->new(%tt_config);
    $Template::Stash::PRIVATE = undef if $self->config->{show_private_variables};
    return $tt;
}

sub render {
    my ( $self, $template, $tokens ) = @_;

    my $content = '';
    my $charset = $self->charset;
    my @options = length($charset) ? ( binmode => ":encoding($charset)" ) : ();
    $self->engine->process( $template, $tokens, \$content, @options )
      or croak 'Failed to render template: ' . $self->engine->error;

    return $content;
}

# Override *_pathname methods from Dancer2::Core::Role::Template
# Let TT2 do the concatenation of paths to template names.
#
# TT2 will look in a its INCLUDE_PATH for templates.
# Typically $self->views is an absolute path, and we set ABSOLUTE=> 1 above.
# In that case TT2 does NOT iterate through what is set for INCLUDE_PATH
# However, if its not absolute, we want to allow TT2 iterate through the
# its INCLUDE_PATH, which we set to be $self->views.

sub view_pathname {
    my ( $self, $view ) = @_;
    return $self->_template_name($view);
}

sub layout_pathname {
    my ( $self, $layout ) = @_;
    return path(
        $self->layout_dir,
        $self->_template_name($layout),
    );
}

sub pathname_exists {
    my ( $self, $pathname ) = @_;
    my $exists = eval {
        # dies if pathname can not be found via TT2's INCLUDE_PATH search
        $self->engine->service->context->template( $pathname );
        1;
    };
    $self->log_cb->( debug => $@ ) if ! $exists;
    return $exists;
}

1;

__END__
