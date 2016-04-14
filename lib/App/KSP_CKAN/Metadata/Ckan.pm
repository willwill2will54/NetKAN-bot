package App::KSP_CKAN::Metadata::Ckan;

use v5.010;
use strict;
use warnings;
use autodie;
use Method::Signatures 20140224;
use Config::JSON; # Saves us from file handling
use List::MoreUtils 'any';
use Carp qw( croak );
use Moo;
use namespace::clean;

# ABSTRACT: Metadata Wrapper for CKAN files

# VERSION: Generated by DZP::OurPkg:Version

=head1 SYNOPSIS

  use App::KSP_CKAN::Metadata::Ckan;

  my $ckan = App::KSP_CKAN::Metadata::Ckan->new(
    file => "/path/to/file.ckan",
  );

=head1 DESCRIPTION

Provides a ckan metadata object for KSP-CKAN. Has the following
attributes available.

=over

=item identifier

Returns the identifier for the loaded CKAN.

=item kind

Returns the kind of CKAN. Default is 'package', but will return 
'metapackage' for CKANs marked as such.

=item download

Returns the download url or 0 (in the case of a metapackage).

=back

=cut

has 'file'          => ( is => 'ro', required => 1 ); # TODO: we should do some validation here.
has '_raw'          => ( is => 'ro', lazy => 1, builder => 1 );
has '_licenses'     => ( is => 'ro', lazy => 1, builder => 1 );
has 'identifier'    => ( is => 'ro', lazy => 1, builder => 1 );
has 'kind'          => ( is => 'ro', lazy => 1, builder => 1 );
has 'download'      => ( is => 'ro', lazy => 1, builder => 1 );
has 'license'      => ( is => 'ro', lazy => 1, builder => 1 );

# TODO: We're already using file slurper + JSON elsewhere. We should
#       pick one method for consistency.
method _build__raw {
  return Config::JSON->new($self->file);
}

# This is an array of explicit licenses which are allowed to be mirrored.
# TODO: Maybe we can consume this from somewhere externally.
method _build__licenses {
 return [
    "public-domain",
    "Apache", "Apache-1.0", "Apache-2.0",
    "Artistic", "Artistic-1.0", "Artistic-2.0",
    "BSD-2-clause", "BSD-3-clause", "BSD-4-clause",
    "ISC",
    "CC-BY", "CC-BY-1.0", "CC-BY-2.0", "CC-BY-2.5", "CC-BY-3.0", "CC-BY-4.0",
    "CC-BY-SA", "CC-BY-SA-1.0", "CC-BY-SA-2.0", "CC-BY-SA-2.5", "CC-BY-SA-3.0", "CC-BY-SA-4.0",
    "CC-BY-NC", "CC-BY-NC-1.0", "CC-BY-NC-2.0", "CC-BY-NC-2.5", "CC-BY-NC-3.0", "CC-BY-NC-4.0",
    "CC-BY-NC-SA", "CC-BY-NC-SA-1.0", "CC-BY-NC-SA-2.0", "CC-BY-NC-SA-2.5", "CC-BY-NC-SA-3.0", "CC-BY-NC-SA-4.0",
    "CC-BY-NC-ND", "CC-BY-NC-ND-1.0", "CC-BY-NC-ND-2.0", "CC-BY-NC-ND-2.5", "CC-BY-NC-ND-3.0", "CC-BY-NC-ND-4.0",
    "CC0",
    "CDDL", "CPL",
    "EFL-1.0", "EFL-2.0",
    "Expat", "MIT",
    "GPL-1.0", "GPL-2.0", "GPL-3.0",
    "LGPL-2.0", "LGPL-2.1", "LGPL-3.0",
    "GFDL-1.0", "GFDL-1.1", "GFDL-1.2", "GFDL-1.3",
    "GFDL-NIV-1.0", "GFDL-NIV-1.1", "GFDL-NIV-1.2", "GFDL-NIV-1.3",
    "LPPL-1.0", "LPPL-1.1", "LPPL-1.2", "LPPL-1.3c",
    "MPL-1.1",
    "Perl",
    "Python-2.0",
    "QPL-1.0",
    "W3C",
    "Zlib",
    "Zope",
    "WTFPL",
    "open-source", "unrestricted" ];
}

method _build_identifier {
  return $self->_raw->{config}{identifier};
}

method _build_kind {
  return $self->_raw->{config}{kind} ? $self->_raw->{config}{kind} : 'package' ;
}

method _build_download {
  return $self->_raw->{config}{download} ? $self->_raw->{config}{download} : 0;
}

method _build_license {
  return $self->_raw->{config}{license} ? $self->_raw->{config}{license} : "unknown";
}

=method is_metapackage

  $ckan->is_package;

Shortcut method so we can test that the CKAN is a package. Returns
'1' if it is a package, otherwise '0'.

=cut

method is_package {
  if ( $self->kind eq 'package' ) {
    return 1;
  }
  return 0;
}

=method can_mirror

  $ckan->can_mirror.

Shortcut method for deciding if the license allows us to mirror it.
Returns '1' if allowed, '0' if not.

=cut

method can_mirror {
  if ( (any { $_ eq $self->license } @{$self->_licenses}) && $self->is_package ) {
    return 1;
  }
  return 0;
}

1;
