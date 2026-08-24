// The single application-level file for every navigation argument class
// (see requirments/routes.md §3). `ag g m` maintains this automatically
// for detail/child modules — there must never be more than one of this
// file in the application.

class PostDetailsPageArgument {
  const PostDetailsPageArgument({required this.postId});
  final int postId;
}

class PostDetailsCommentsPageArgument {
  const PostDetailsCommentsPageArgument({required this.postId});
  final int postId;
}
