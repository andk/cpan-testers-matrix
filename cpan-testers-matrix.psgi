#!perl

use strict;
use warnings;
use FindBin;

use Plack::Builder;
use Plack::App::Directory;
use Plack::App::File;
use Plack::App::WrapCGI;

use Cwd 'cwd';
use File::Basename 'basename';
use File::Spec::Functions 'catfile', 'splitpath';
use File::Glob 'bsd_glob';

my $root = $FindBin::RealBin;

my $favicon = Plack::App::File->new(
    file => catfile($root, 'images', 'cpantesters_favicon.ico'),
);

my @mounts;
for my $htdoc (bsd_glob(catfile($root, 'htdocs', '*'))) {
    my $location = '/' . basename($htdoc);
    if (-d $htdoc) {
	push @mounts,  [ $location => Plack::App::Directory->new({root => $htdoc}) ];
    } elsif (-f $htdoc) {
	push @mounts, [ $location => Plack::App::File->new(file => $htdoc) ];
    } else {
	warn "Ignoring $htdoc...\n";
    }
}

builder {
    mount '/favicon.ico' => $favicon;
    mount '/cpantesters_favicon.ico' => $favicon;

    mount '/images' => Plack::App::File->new(file => catfile($root, 'images'));

    for my $mount (@mounts) {
	mount $mount->[0] => $mount->[1];
    }

    mount '/' => Plack::App::WrapCGI->new(
        script  => catfile($root, 'cgi-bin', 'cpantestersmatrix.pl'),
        execute => 1,
    )->to_app;
};
