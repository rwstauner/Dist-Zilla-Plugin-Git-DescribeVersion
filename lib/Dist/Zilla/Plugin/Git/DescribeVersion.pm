# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;

package Dist::Zilla::Plugin::Git::DescribeVersion;
# ABSTRACT: Provide version using git-describe

use Dist::Zilla 4 ();
use Git::DescribeVersion ();
use Moose;

with 'Dist::Zilla::Role::VersionProvider';

while( my ($name, $default) = each %Git::DescribeVersion::Defaults ){
  has $name => ( is => 'ro', isa=>'Str', default => $default );
}

sub provide_version {
  my ($self) = @_;

  # override (or maybe needed to initialize)
  return $ENV{V} if exists $ENV{V};

  # less overhead to use %Defaults than MOP meta API
  my $opts = { map { $_ => $self->$_() }
    keys %Git::DescribeVersion::Defaults };

  my $new_ver = eval {
    Git::DescribeVersion->new($opts)->version;
  };

  $self->log_fatal("Could not determine version from tags: $@")
    unless defined $new_ver;

  $self->log("Git described version as $new_ver");

  $self->zilla->version("$new_ver");
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;

=for Pod::Coverage
    provide_version

=head1 SYNOPSIS

In your F<dist.ini>:

  [Git::DescribeVersion]
  match_pattern  = v[0-9]*     ; this is the default

=head1 DESCRIPTION

This performs the L<Dist::Zilla::Role::VersionProvider> role.
It uses L<Git::DescribeVersion> to count the number of commits
since the last tag (matching I<match_pattern>) or since the initial commit,
and uses the result as the I<version> parameter for your distribution.

The plugin accepts the same options as
L<Git::DescribeVersion/new>.
See L<Git::DescribeVersion/OPTIONS>.

You can also set the C<V> environment variable to override the new version.
This is useful if you need to bump to a specific version.  For example, if
the last tag is 0.005 and you want to jump to 1.000 you can set V = 1.000.

  $ V=1.000 dzil release

=head1 USAGE

B<Note>: Since L<Git::DescribeVersion>
appends the third part to a two-part version tag
(for example, a tag of C<v1.2> becomes C<v1.2.35>)
This plugin is not designed to be combined with
L<Dist::Zilla::Plugin::Git::Tag>
(which will tag the repo with the generated version).

Instead it works better with manual tags.
For example, you might manually increase the minor version
(from C<v1.2> to C<v1.3>) when a big feature is added or the API changes.
Then each build will append the number of commits as the revision number
(C<v1.3> becomes C<v1.3.28>).

This is probably more useful for projects without formal releases.
This is in fact the only way that the author still uses the module:
For C<$work> projects where builds are deployed often
to a variety of internal environments.

For projects released to the world I suggest using the simple and logical
L<Dist::Zilla::Plugin::Git::NextVersion>
which does work nicely with
L<Dist::Zilla::Plugin::Git::Tag>.

=head1 SEE ALSO

=for :list
* L<Git::DescribeVersion>
* L<Dist::Zilla>
* L<Dist::Zilla::Plugin::Git::NextVersion>

=cut
