$c->{plugins}->{"Screen::EPrint::Box::CollectionMembership"}->{params}->{disable} = 0;
$c->{plugins}->{"Screen::EPrint::Box::CollectionMembership"}->{appears}->{summary_top} = undef;
$c->{plugins}->{"Screen::EPrint::Box::CollectionMembership"}->{appears}->{summary_right} = 1100;
$c->{plugins}->{"Screen::EPrint::Box::CollectionMembership"}->{appears}->{summary_bottom} = undef;
$c->{plugins}->{"Screen::EPrint::Box::CollectionMembership"}->{appears}->{summary_left} = undef;
$c->{plugins}->{"Collection"}->{params}->{disable} = 0;
$c->{plugins}->{"InputForm::Component::Field::CollectionSelect"}->{params}->{disable} = 0;
$c->{plugins}->{"Screen::NewCollection"}->{params}->{disable} = 0;
$c->{plugins}->{"Screen::EPrint::CollectionEdit"}->{params}->{disable} = 0;
$c->{plugin_alias_map}->{"Screen::EPrint::Edit"} = "Screen::EPrint::CollectionEdit";


$c->{z_collection_validate_eprint} = $c->{validate_eprint};

$c->{validate_eprint} = sub
{
	my( $eprint, $session, $for_archive ) = @_;

	my @problems = ();

	if( $eprint->get_type eq 'collection' ){
		return( @problems );
	}

	@problems = $session->get_repository()->call("z_collection_validate_eprint", $eprint, $session, $for_archive);

	return( @problems );
};

$c->{z_collection_eprint_warnings} = $c->{eprint_warnings};

$c->{eprint_warnings} = sub
{
        my( $eprint, $session ) = @_;

        my @problems = ();

        if( $eprint->get_type eq 'collection' ){
                return( @problems );
        }

        @problems = $session->get_repository()->call("z_collection_eprint_warnings", $eprint, $session );

        return( @problems );
};

$c->{collection_session_init} = $c->{session_init};

$c->{session_init} = sub {
        my ($repository, $offline) = @_;

        push @{$repository->{types}->{eprint}}, "collection";

        $repository->call("collection_session_init");
}

$c->{collection_eprint_render} = $c->{eprint_render};

#overwrite collection_render in order to make a custom render method for collections
$c->{collection_render} = $c->{eprint_render};

$c->{eprint_render} = sub
{
        my( $eprint, $session, $preview ) = @_;
	
	if( $eprint->value("type") ne "collection" )
	{
        	return $session->get_repository->call("collection_eprint_render", $eprint, $session, $preview );
	}
	
        return $session->get_repository->call("collection_render", $eprint, $session, $preview );
};

