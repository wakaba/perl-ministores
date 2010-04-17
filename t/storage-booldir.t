package test::Storage::BoolDir;
use strict;
use warnings;
use base qw(Test::Class);
use Path::Class;
use lib file (__FILE__)->dir->parent->subdir ('lib')->stringify;
use Storage::BoolDir;
use File::Temp qw(tempdir);
use Test::More;
use Test::Differences;

my $temp_root_d = dir (tempdir);

sub temp_d () {
  my $d = $temp_root_d->subdir (rand);
  $d->mkpath;
  return $d;
} # temp_d

sub storage () {
  return Storage::BoolDir->new (data_d => temp_d);
} # storage

sub _new_without_d : Test(1) {
  eval {
    my $storage = Storage::BoolDir->new;
    ok 0;
  } or do {
    ok 1;
  };
} # _new_without_d

sub _new_from_data_directory_name : Test(2) {
  my $d_name = temp_d . '';
  my $storage = Storage::BoolDir->new (data_directory_name => $d_name);
  isa_ok $storage->data_d, 'Path::Class::Dir';;
  is $storage->data_d, $d_name;
} # _new_from_data_directory_name

sub _escape : Test(16) {
  my $storage = storage;
  for (
    [undef, '.bool'],
    ['', '.bool'],
    [0, '0.bool'],
    [1, '1.bool'],
    ['abcdefF', 'abcdefF.bool'],
    ['a<>.bool', 'a_3C_3E_2Ebool.bool'],
    ['-_A[A-Z]/..', '_2D_5FA_5BA_2DZ_5D_2F_2E_2E.bool'],
    ["\x{4e00}ab\xFE", '_E4_B8_80ab_C3_BE.bool'],
  ) {
    is $storage->_escape ($_->[0]), $_->[1];
    is $storage->_unescape ($_->[1]),
        ((defined $_->[0] and length $_->[0]) ? $_->[0] : undef);
  }
} # _escape

sub _unescape_invalid : Test(13) {
  my $storage = storage;
  for (
    undef,
    '',
    '.',
    '..',
    '...',
    '.bool',
    'file',
    'ABC.boolean',
    'abc.BOOL',
    'foo.bool ',
    'aaa.boo',
    'abc.bool.xyz',
    'foo.bool/abc',
  ) {
    is $storage->_unescape ($_), undef;
  }
} # _unescape_invalid

sub _get_set : Test(14) {
  my $storage = storage;

  ok !$storage->get ('abc');
  ok !$storage->get ('0');
  ok !$storage->get ('');

  $storage->set (abc => 1);
  
  ok $storage->get ('abc');
  ok !$storage->get ('ABC');
  ok !$storage->get ('');

  $storage->set (0 => 1);

  ok $storage->get ('0');
  ok !$storage->get ('');

  $storage->set (abc => 0);
  
  ok !$storage->get ('abc');
  ok $storage->get ('0');

  $storage->set ("abc\x{4e00}" => 1);
  
  ok $storage->get ("abc\x{4e00}");

  $storage->set ('' => 1);
  
  ok !$storage->get ('');

  $storage->set (undef, 1);

  ok !$storage->get ('');

  eq_or_diff $storage->keys->sort (sub { $_[0] cmp $_[1] })->to_a,
      ['0', "abc\x{4e00}"];
} # _get_set

__PACKAGE__->runtests;

1;

=head1 LICENSE

Copyright 2010 Wakaba <w@suika.fam.cx>

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
