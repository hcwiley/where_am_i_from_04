class ImageLoader
{

  PImage[] imgs;
  // Keeps track of loaded images (true or false)
  boolean[] loadStates;
  int imgCount;

  ImageLoader(String srcDir, int _imgCount, int zeroPadding, int startIdx)
  {

    imgCount = _imgCount;
    imgs = new PImage[imgCount];
    loadStates = new boolean[imgCount];


    // Load images asynchronously
    for (int i = 0; i < imgCount; i++) {
      imgs[i] =
        //loadImage
        requestImage
        (srcDir + "/" + nf(i + startIdx, zeroPadding) + ".jpg");
    }
  }

  /**
   * @brief Check if individual images are fully loaded
   */
  int checkLoadCount()
  {
    int fullyLoaded = 0;
    for (int i = 0; i < imgs.length; i++) {
      if ((imgs[i].width != 0) && (imgs[i].width != -1)) {
        // As images are loaded set true in boolean array
        loadStates[i] = true;
        fullyLoaded++;
      }
    }
    return fullyLoaded;
  }

  void applyFilter(int filterType)
  {
    for (int i = 0; i < imgs.length; i++) {
      imgs[i].filter(filterType);
    }
  }

  void drawImage(int idx, int x, int y, int w, int h, int overlay, int opacity)
  {

    tint(overlay, opacity);

    // get the right idx. allow modulo and negative end indexing
    int correctedIdx = idx;
    if (correctedIdx < 0) {
      correctedIdx = (imgs.length - idx) % imgs.length;
    }
    if (correctedIdx >= imgs.length) {
      correctedIdx = idx % imgs.length;
    }

    if (imgs[correctedIdx].width <= 0) {
      // log a warning
      println("ImageLoader::drawImage: image not loaded: %d", idx);
      return;
    }


    // ok cool, draw the thing
    image(imgs[correctedIdx], x, y, w, h);
  }
}
