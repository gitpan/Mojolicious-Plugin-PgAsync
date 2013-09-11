package Mojolicious::Plugin::PgAsync;
use Mojo::Base 'Mojolicious::Plugin';

use DBD::Pg ':async';
use Data::Dumper;
use Mojolicious::Plugin::PgAsync::Pool;

our $VERSION = '0.02';

has ttl => 30;
has pool => sub { Mojolicious::Plugin::PgAsync::Pool->new };

our $debug = $ENV{DEBUG_PG};

sub register {
	my ($self, $app, $config) = @_;

	$self->pool->dbi($config->{dbi})->ttl($config->{ttl} || $self->ttl);

	$app->renderer->add_helper(pg => sub{ $self->execute(@_) });
	$app->renderer->add_helper(pg_listen => sub{ $self->listen(@_) });
}

sub execute {
	my $self = shift;
	my $c = shift;
	my $cb = pop;
	my($sql, $attr, @values) = @_;

	$self->pool->get
		->callback($cb)
		->sql($sql)
		->attr($attr)
		->execute(\@values)
		;
}

sub listen {
	my $self = shift;
	my $c = shift;
	my $cb = pop;
	my($channel) = @_;

	$self->pool->get
		->callback($cb)
		->listen($channel)
		;
}

1

__END__

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::PgAsync - Mojolicious Plugin for asynchronous work with PostgreSQL

=head1 SYNOPSIS

	# Mojolicious::Lite
	plugin PgAsync => {dbi => ['dbi:Pg:dbname=test', 'postgres', '', {AutoCommit => 1, RaiseError => 1}]};

	# in controller
	$self->pg('SELECT 3 as id, pg_sleep(?)', undef, 3,
		sub {
			my $db = shift;
			my $info = $db->sth->fetchall_arrayref({});
			$self->render(text => $info->[0]{id});
		}
	);


=head1 DESCRIPTION

L<Mojolicious::Plugin::PgAsync> is a plugin for Mojolicious apps to work asynchronous with PostgreSQL
using L<DBD::Pg>, include I<listen> feature. Plugin uses own connections pool.

=head1 HELPERS

L<Mojolicious::Plugin::PgAsync> contains two helpers: I<pg> and I<pg_listen>.

=head2 C<pg>

Like L<DBI> method L<DBI#do> or L<DBI#selectall_arrayref> execute a single statement. Callback return
object Mojolicious::Plugin::PgAsync::Db contains methods I<dbh> and I<sth> for fetch result or commit
transaction.

	$self->pg('UPDATE test SET name=?', undef, 'foo',
		sub {
			my $db = shift;
			my $rv = $db->sth->rows;
			$db->dbh->commit if $rv == 1;
		}
	);

=head2 C<pg_listen>

Listen for a notification.

	$self->pg_listen('foo', sub {
		my $notify = shift;
		$self->render(text => 'channel '.$notify->{channel});
	});

Callback return hashref with keys I<channel>(alias I<name>), I<pid> and I<payload>.

=head1 ATTRIBUTES

L<Mojolicious::Plugin::PgAsync> contains the following attributes:

=head2 C<dbi>

Arrayref of L<DBI> parameters for connect to PostgreSQL DB.

=head2 C<ttl>

Time to life for idle connections, seconds. Default - 30.

=head1 AUTHOR

Alexander Romanenko <romanenko@cpan.org>

=head1 COPYRIGHT & LICENSE

Copyright (C) 2013 by Alexander Romanenko.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
