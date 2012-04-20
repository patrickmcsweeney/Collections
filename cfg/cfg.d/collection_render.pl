## over write colllection render to use eprint render

$c->{collection_render} = sub
{
	my( $collection, $session, $preview ) = @_;

	return $session->get_repository->call("eprint_render", $collection, $session, $preview );
};
