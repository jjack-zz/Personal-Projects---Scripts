#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;

use DateTime;
use XML::Feed;
use Net::Twitter;
use Cache::FileCache;

my $WOW_NAME = "Hats";
my $TWITTER_USER = "hatsthedruid";
my $TWITTER_PASSWORD = "lolsecurelol";
my $cache = new Cache::FileCache::({ 'namespace' => 'wowtwitter' });
my $last_update = $cache->get('last_update') || DateTime->new( year => 1970 );
my $last_entry = $cache->get('last_entry') || "xx";

my $feed = XML::Feed->parse(URI->new('http://www.wowarmory.com/character-feed.atom?r=Maelstrom&cn=$WOW_NAME&locale=en_US'));

my @items;
my $newest_update;
my $newest_entry;
foreach my $entry ( $feed->entries ) {
   next unless ( $entry->issued gt $last_update );
   $newest_update = $entry->issued unless ($newest_update);
   $newest_entry = $entry->title unless ($newest_entry);
   push @items, $entry->title;
}

# nothing new. carry on.
exit unless (@items);

@items = reverse @items;

# update the newness
$cache->set('last_update', $newest_update) if ( $newest_update ne $last_update );
$cache->set('last_entry', $newest_entry) if ( $newest_entry ne $last_entry );

my $twit = Net::Twitter->new(
   traits => [qw/API::REST/],
   username => $TWITTER_USER,
   password => $TWITTER_PASSWORD
);

foreach my $item ( @items ) {
   $twit->update($item) unless ($item eq $last_entry);
   #print "$item\n" unless ($item eq $last_entry);
}
