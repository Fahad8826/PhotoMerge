
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:photomerge/User/View/home.dart';
import 'package:photomerge/User/View/imagedetails.dart';
import 'package:photomerge/User/View/provider/listimageprovider.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:async';

class ListImages extends StatefulWidget {
  const ListImages({Key? key}) : super(key: key);

  @override
  State<ListImages> createState() => _ListImagesState();
}

class _ListImagesState extends State<ListImages> {
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<ImageProviderService>(context, listen: false);
    provider.fetchImages();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !provider.isLoading &&
          provider.hasMore) {
        if (_debounce?.isActive ?? false) _debounce!.cancel();
        _debounce = Timer(const Duration(milliseconds: 300), () {
          provider.fetchImages();
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ImageProviderService>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.white,
            title: Text(
              'Gallery',
              style: GoogleFonts.poppins(
                color: const Color(0xFF00A19A),
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            automaticallyImplyLeading: false,
            leading: IconButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => UserDashboard()),
                );
              },
              icon: const Icon(Icons.arrow_back, color: Color(0xFF00A19A)),
            ),
          ),
          body: provider.documents.isEmpty && provider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () => provider.fetchImages(refresh: true),
                  child: GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount:
                        provider.documents.length + (provider.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == provider.documents.length &&
                          provider.hasMore) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final photo = provider.documents[index].data()
                          as Map<String, dynamic>;
                      final photoId = provider.documents[index].id;
                      final photoUrl = photo['image_url'];

                      return GestureDetector(
                        onTap: () {
                          precacheImage(
                            CachedNetworkImageProvider(photoUrl),
                            context,
                          ).then((_) {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder:
                                    (context, animation, secondaryAnimation) =>
                                        ImageDetailView(
                                  photoId: photoId,
                                  photoUrl: photoUrl,
                                ),
                                transitionsBuilder: (context, animation,
                                    secondaryAnimation, child) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  );
                                },
                                transitionDuration:
                                    const Duration(milliseconds: 30),
                              ),
                            );
                          });
                        },
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: CachedNetworkImage(
                            imageUrl: photoUrl,
                            fit: BoxFit.cover,
                            memCacheHeight: 200,
                            memCacheWidth: 200,
                            placeholder: (context, url) => Shimmer.fromColors(
                              baseColor: Colors.grey[300]!,
                              highlightColor: Colors.grey[100]!,
                              child: Container(color: Colors.grey[300]),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[200],
                              child: const Icon(Icons.error,
                                  size: 48, color: Colors.red),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        );
      },
    );
  }
}
