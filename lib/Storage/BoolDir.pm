package Storage::BoolDir;
use strict;
use warnings;

sub new ($%) {
  my ($class, %args) = @_;
  my $self = bless {
    data_file_suffix => '.bool',
  }, $class;
  if ($args{data_directory_name}) {
    require Path::Class;
    $self->{data_d} = Path::Class::dir ($args{data_directory_name});
  } elsif ($args{data_d}) {
    $self->{data_d} = $args{data_d};
  } else {
    die "data_d or data_directory_name has to be specified";
  }
  return $self;
} # new

sub data_d ($) {
  return $_[0]->{data_d};
} # data_d

sub _escape ($$) {
  require Encode;
  my $s = Encode::encode ('utf8', $_[1]);
  $s =~ s/([^0-9A-Za-z])/sprintf '_%02X', ord $1/ge;
  $s .= $_[0]->{data_file_suffix};
  return $s;
} # _escape

sub _unescape ($$) {
  my ($self, $s) = @_;
  return undef unless defined $s;
  return undef
      unless $s =~ /\A(?:[0-9A-Za-z]|_[0-9A-F]{2})+\Q$self->{data_file_suffix}\E\z/;
  substr ($s, -length $self->{data_file_suffix}) = '';
  $s =~ s/_([0-9A-F]{2})/pack 'C', hex $1/ge;
  require Encode;
  return Encode::decode ('utf8', $s);
} # _unescape

sub _get_f ($$) {
  my $self = shift;
  return $self->data_d->file ($self->_escape ($_[0]));
} # _get_f

sub get ($$) {
  my $self = shift;
  return 0 if not defined $_[0] or not length $_[0];
  my $f = $self->_get_f ($_[0]);
  return -f $f;
} # get_value

sub set ($$$) {
  my $self = shift;
  return if not defined $_[0] or not length $_[0];
  my $f = $self->_get_f ($_[0]);
  if ($_[1]) {
    if (-f $f) {
      #
    } else {
      $f->touch;
    }
  } else {
    if (-f $f) {
      unlink $f;
    } else {
      #
    }
  }
} # set_value

sub keys ($) {
  my $self = shift;
  require List::Rubyish;
  return List::Rubyish->new ([
    ($self->data_d->children)
  ])->grep (sub {
    -f $_;
  })->map (sub {
    $self->_unescape ($_->basename);
  })->grep (sub {
    defined $_
  });
} # values

1;

=head1 LICENSE

Copyright 2010 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
