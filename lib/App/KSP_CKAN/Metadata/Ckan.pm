package App::KSP_CKAN::Metadata::Ckan;

use v5.010;
use strict;
use warnings;
use autodie;
use Method::Signatures 20140224;
use Config::JSON; # Saves us from file handling
use List::MoreUtils 'any';
use Carp qw( croak );
use Digest::SHA 'sha1_hex';
use URI::Escape 'uri_unescape';
use Scalar::Util 'reftype';
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

=item abstract

Returns the abstract for the loaded CKAN.

=item author

Returns the author field of the loaded CKAN. This could be a single
'author' or an array of 'authors'.

=item authors

Returns the author field of the loaded CKAN as an array regardless
of whether there is a single author or multiple.

=item kind

Returns the kind of CKAN. Default is 'package', but will return 
'metapackage' for CKANs marked as such.

=item download

Returns the download url or 0 (in the case of a metapackage).

=item download_sha1

Returns the download sha1 hash or 0 if not present.

=item download_sha256

Returns the download sha256 hash or 0 if not present.

=item download_content_type

Returns the download content type or 0 if not present.

=item homepage

Returns the homepage url or 0.

=item repository

Returns the download url or 0.

=item version

Returns the version field of the loaded CKAN.

=item escaped_version

Returns the version field of the loaded CKAN with the colons replaced
with dashes.

=back

=cut

has 'file'                  => ( is => 'ro', required => 1 ); # TODO: we should do some validation here.
has '_raw'                  => ( is => 'ro', lazy => 1, builder => 1 );
has 'identifier'            => ( is => 'ro', lazy => 1, builder => 1 );
has 'authors'               => ( is => 'ro', lazy => 1, builder => 1 );
has 'author'                => ( is => 'ro', lazy => 1, builder => 1 );
has 'name'                  => ( is => 'ro', lazy => 1, builder => 1 );
has 'abstract'              => ( is => 'ro', lazy => 1, builder => 1 );
has 'kind'                  => ( is => 'ro', lazy => 1, builder => 1 );
has 'download'              => ( is => 'ro', lazy => 1, builder => 1 );
has 'download_sha1'         => ( is => 'ro', lazy => 1, builder => 1 );
has 'download_sha256'       => ( is => 'ro', lazy => 1, builder => 1 );
has 'download_content_type' => ( is => 'ro', lazy => 1, builder => 1 );
has 'homepage'              => ( is => 'ro', lazy => 1, builder => 1 );
has 'repository'            => ( is => 'ro', lazy => 1, builder => 1 );
has 'license'               => ( is => 'ro', lazy => 1, builder => 1 );
has 'version'               => ( is => 'ro', lazy => 1, builder => 1 );
has 'escaped_version'       => ( is => 'ro', lazy => 1, builder => 1 );

# TODO: We're already using file slurper + JSON elsewhere. We should
#       pick one method for consistency.
# TODO: This could also barf out on an invalid file, we'll need to
#       Handle that somewhere.
method _build__raw {
  return Config::JSON->new($self->file);
}

method _build_identifier {
  return $self->_raw->{config}{identifier};
}

method _build_kind {
  return $self->_raw->{config}{kind} ? $self->_raw->{config}{kind} : 'package' ;
}

method _build_version{
  return $self->_raw->{config}{version};
}

method _build_download {
  return $self->_raw->{config}{download} ? $self->_raw->{config}{download} : 0;
}

method _build_license {
  return $self->_raw->{config}{license} ? $self->_raw->{config}{license} : "unknown";
}

method _build_download_sha1 {
  return $self->_raw->{config}{download_hash}{sha1} ? $self->_raw->{config}{download_hash}{sha1} : 0;
}

method _build_download_sha256 {
  return $self->_raw->{config}{download_hash}{sha256} ? $self->_raw->{config}{download_hash}{sha256} : 0;
}

method _build_download_content_type {
  return $self->_raw->{config}{download_content_type} ? $self->_raw->{config}{download_content_type} : 0;
}

method _build_authors {
  my $authors = $self->_raw->{config}{author};
  my @authors = reftype \$authors ne "SCALAR" ? @{$authors} : $authors;
  return \@authors;
}

method _build_author {
 return $self->_raw->{config}{author};
}

method _build_name {
 return $self->_raw->{config}{name};
}

method _build_abstract {
 return $self->_raw->{config}{abstract};
}

method _build_homepage {
 return $self->_raw->{config}{resources}{homepage};
}

method _build_repository {
 return $self->_raw->{config}{resources}{repository};
}

method _build_escaped_version {
  # Epochs in the version appear as a colon.
  my $version = $self->version;
  $version =~ s/:/-/g;
  return $version;
}

=method licenses
  
  $ckan->licenses();

Returns the license field as an array. Because unless there is
multiple values it won't be.

=cut
 
# Sometimes we always want an array. 
method licenses { 
  my @licenses = reftype \$self->license ne "SCALAR" ? @{$self->license} : $self->license;
  return \@licenses;
}

=method redistributable

  $ckan->redistributable;

Shortcut method so we can test that the CKAN is redistributable. Returns
'1' if it has a license which allows distribution, otherwise '0'.

=cut

method redistributable {
  foreach my $license (@{$self->licenses}) {
    if (any { $_ eq $license } @{$self->redistributable_licenses}) {
      return 1;
    }
  }
  return 0;
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

  $ckan->can_mirror;

Shortcut method for deciding if the license allows us to mirror it.
Returns '1' if allowed, '0' if not.

=cut

method can_mirror {
  if ( ! $self->is_package ) {
    return 0;
  } elsif ( ! $self->redistributable ) {
    return 0;
  } elsif ( ! $self->extension($self->download_content_type) ) {
    return 0;
  }
  return 1;
}

=method url_hash

  $ckan->url hash;
  
Produces a url hash in the same format as the 'NetFileCache.cs' 
method 'CreateURLHash'.

=cut

method url_hash {
  my $hash = sha1_hex(uri_unescape($self->download));
  $hash =~ s/-//g;
  return uc(substr $hash, 0, 8);
}

=method mirror_item

  $ckan->mirror_item;

Produces an item name based of the 'identifier' and 'version'. 

=cut

method mirror_item {
  return $self->identifier."-".$self->escaped_version;
}

=method mirror_filename

  $ckan->mirror_filename;

Produces a filename based of the first 8 digits in sha1 hash,
the 'identifier' and the 'version' in the metadata if the
download_hash exists. Returns '0' if there is no download hash
or has an content type other than zip/gz/tar/tar.gz.

=cut

method mirror_filename {
  if ( ! $self->download_sha1 ) {
    return 0;
  } elsif ( ! $self->extension($self->download_content_type) ) {
    return 0;
  }
  return 
    substr($self->download_sha1,0,8)."-"
    .$self->identifier."-"
    .$self->escaped_version."."
    .$self->extension($self->download_content_type);
}

=method mirror_url

  $ckan->mirror_url'

Produces a mirror url based of the 'identifier' and 'version'. 

=cut

method mirror_url {
  # TODO: Maybe not hardcode this.
  return "https://archive.org/details/".$self->identifier."-".$self->escaped_version;
}

with('App::KSP_CKAN::Roles::Licenses','App::KSP_CKAN::Roles::FileServices');

1;
