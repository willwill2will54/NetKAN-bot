package App::KSP_CKAN::Roles::FileServices;

use v5.010;
use strict;
use warnings;
use autodie;
use Method::Signatures 20140224;
use Moo::Role;
use experimental 'switch';

# ABSTRACT: File services role for consuming

# VERSION: Generated by DZP::OurPkg:Version

=head1 SYNOPSIS

  with('App::KSP_CKAN::Roles::FileServices');

=head1 DESCRIPTION

Provides various file operations.

extensions.

=cut

=method extension

  $self->extension( "application/zip" );

Returns a file extension for a given valid upload mimetype.

=cut

method extension($mimetype) {
  given ( $mimetype ) {
    when ( "application/x-gzip" )           { return "gz"; }
    when ( "application/x-tar" )            { return "tar"; }
    when ( "application/x-compressed-tar" ) { return "tar.gz"; }
    when ( "application/zip" )              { return "zip"; }
  }
  return 0;
}

1;