#!/usr/bin/perl

use Modern::Perl;
use HTML::TreeBuilder;
use Plient;
use URI::Escape;
use Data::Dumper;
use WWW::Bugzilla3;
use YAML qw/LoadFile/;

my $conf = LoadFile('config.yml');
my $sn = $conf->{sn};
my $token = $conf->{token};
my $search_url = $conf->{search_url};
my $url = "http://bugs.koha-community.org/bugzilla3/buglist.cgi?$search_url";

my $tree = HTML::TreeBuilder->new_from_url($search_url);
my @tr = $tree->look_down(_tag => 'tr', class => qr/bz_bugitem/);
my @bugs;
foreach my $line (@tr) {
    my @tds = $line->look_down(_tag => 'td');
    my ($id, $product, $comp, $assignee, $status, $resolution, $summary, $changed) = map { $_->as_text } @tds;

    my $history_url = "http://bugs.koha-community.org/bugzilla3/show_activity.cgi?id=$id";
    my $history_tree = HTML::TreeBuilder->new_from_url($history_url);
    my @history_trs = $history_tree->look_down(_tag => 'tr');
    foreach my $htr (@history_trs) {
        my (undef, $date, undef, undef, $status) = map { $_->as_text } $htr->look_down(_tag => 'td');
        say Dumper [undef, $date, undef, undef, $status];
        if ($status =~ "Pushed to Master") {
            push @bugs, {
                id => $id,
                assignee => $assignee,
                date => $date,
            };
        }
    }
}

foreach my $bug (@bugs) {
    my $assignee = $bug->{assignee};
    my $id = $bug->{id};
    $assignee =~ s/\./ /g;
    $assignee =~ s/jonathan/jonatent/;
    my $msg = uri_escape("Bravo $assignee, ton patch $id vient d'être poucher. Tu as gagné une image!");
    say $msg;
    system("curl 'http://api.nabaztag.com/vl/FR/api.jsp?sn=$sn&token=$token&tts=$msg'");
    sleep 20;
}
