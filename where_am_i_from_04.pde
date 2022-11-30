import ddf.minim.*;
import ddf.minim.analysis.*;

Minim minim;
AudioPlayer song;
BeatDetect beat;
BeatListener bl;

boolean drawBeatText = false;

float kickSize, snareSize, hatSize;

// For loading animation
float loaderX, loaderY, theta;

ImageLoader drawingImages, paintingImages;
int imageFrameRate = 3;
int frameCount = 0;
long totalElapsed = 0;

int drawingOpacity = 0;
float drawingOpacityDecay = 0.1;

int paintingOpacity = 0;
float paintingOpacityDecay = 0.1;

String mp3Names[] = { "a_earsnake.mp3",         "b_disposablechurch.mp3",
                      "b_ghastlytask.mp3",      "c_earthrisehigh.mp3",
                      "c_musclememoryloss.mp3", "c_soulcoat.mp3",
                      "c_stutterface_1122.mp3", "c_thinlinedance.mp3",
                      "z_coleandthefliesb.mp3" };

void
setup()
{
  long start = millis();
  size(512, 512, P3D);
  fullScreen();
  frameRate(60);

  minim = new Minim(this);

  song = minim.loadFile(mp3Names[4], 2048);
  // song.skip(30 * 1000);
  // a beat detection object that is FREQ_ENERGY mode that
  // expects buffers the length of song's buffer size
  // and samples captured at songs's sample rate
  beat = new BeatDetect(song.bufferSize(), song.sampleRate());
  beat.setSensitivity(10);
  kickSize = snareSize = hatSize = 16;
  // make a new beat listener, so that we won't miss any buffers for the
  // analysis
  bl = new BeatListener(beat, song);
  textFont(createFont("Helvetica", 16));
  textAlign(CENTER);

  drawingImages = new ImageLoader("drawing", 190, 6, 1);
  paintingImages = new ImageLoader("painting", 190, 6, 1);
  drawingImages.checkLoadCount();
  paintingImages.checkLoadCount();
}

void
draw()
{
  long start = millis();

  // check if we are still loading images
  if (!song.isPlaying()) {
    if (drawingImages.checkLoadCount() == drawingImages.imgCount &&
        paintingImages.checkLoadCount() == paintingImages.imgCount) {
      drawingImages.applyFilter(INVERT);
      song.play();
    } else {
      // do some loading jazz
      runLoaderAni();
    }
  }

  background(0);
  noTint();

  // draw a green rectangle for every detect band
  // that had an onset this frame
  float rectW = width / beat.detectSize();
  for (int i = 0; i < beat.detectSize(); ++i) {
    // test one frequency band for an onset
    if (beat.isOnset(i)) {
      // fill(0, 200, 0);
      // rect(i * rectW, 0, rectW, height);
    }
  }

  // draw an orange rectangle over the bands in
  // the range we are querying
  int lowBand = 5;
  int highBand = 15;
  // at least this many bands must have an onset
  // for isRange to return true
  int numberOfOnsetsThreshold = 4;
  if (beat.isRange(lowBand, highBand, numberOfOnsetsThreshold)) {
    // fill(232,179,2,200);
    // rect(rectW*lowBand, 0, (highBand-lowBand)*rectW, height);
  }

  int nextDrawingOpacity = 0;
  int nextPaintingOpacity = 0;

  if (beat.isKick()) {
    kickSize = 32;
    paintingOpacityDecay += 0.4;
    nextPaintingOpacity = round((paintingOpacity + 5) * 1.4);
  } else {
    paintingOpacityDecay = 0.1;
  }
  if (beat.isSnare()) {
    snareSize = 32;
    nextDrawingOpacity = 255; // round((drawingOpacity + 75) * 1.25);
    drawingOpacityDecay += 0.3;
  } else {
    drawingOpacityDecay -= 0.3;
    nextDrawingOpacity = round((drawingOpacity * 0.7) - 10);
  }
  if (beat.isHat()) {
    hatSize = 32;
    nextPaintingOpacity = round((paintingOpacity + 100) * 1.5);
  }

  nextDrawingOpacity = constrain(nextDrawingOpacity, 0, 255);
  drawingOpacityDecay = constrain(drawingOpacityDecay, 0.0, 1);
  drawingOpacityDecay = pow(pow(drawingOpacityDecay, 10), 0.8);
  // drawingOpacityDecay = pow(pow(drawingOpacityDecay, 2), 0.1);
  drawingOpacityDecay = constrain(drawingOpacityDecay, 0.0, 1);
  drawingOpacity = (int)round(
    lerp(drawingOpacity, (float)nextDrawingOpacity, 1 - drawingOpacityDecay));
  drawingOpacity = constrain(drawingOpacity, 0, 255);

  // blit the drawing image
  drawingImages.drawImage(frameCount, 0, 0, width, height, 255, drawingOpacity);

  nextPaintingOpacity = constrain(nextPaintingOpacity, 0, 255);
  paintingOpacityDecay = constrain(paintingOpacityDecay, 0.0, 1.0);
  paintingOpacity = (int)round(
    lerp(paintingOpacity, (float)nextPaintingOpacity, paintingOpacityDecay));
  paintingOpacity = constrain(paintingOpacity, 0, 255);

  // blit the painting image
  paintingImages.drawImage(
    frameCount, 0, 0, width, height, 255, paintingOpacity);

  noTint();

  if (drawBeatText) {
    fill(55);

    textSize(kickSize);
    text("KICK", width / 4, height / 2);

    textSize(snareSize);
    text("SNARE [" + drawingOpacityDecay + "]", width / 2, height / 2);

    textSize(hatSize);
    text("HAT", 3 * width / 4, height / 2);

    kickSize = constrain(kickSize * 0.95, 16, 32);
    snareSize = constrain(snareSize * 0.95, 16, 32);
    hatSize = constrain(hatSize * 0.95, 16, 32);
  }

  long end = millis();

  // calculate elapsed time
  long elapsed = end - start;
  totalElapsed += elapsed;
  frameCount = (int)round((float)totalElapsed / 1000 * imageFrameRate);

  fill(0);
  rect(0, 0, 100, 20);
  fill(255);
  textSize(20);
  text("frameCount: " + frameCount, 15, 15);
}

// Loading animation
void
runLoaderAni()
{
  // Only run when images are loading
  ellipse(loaderX, loaderY, 10, 10);
  loaderX += 2;
  loaderY = height / 2 + sin(theta) * (height / 8);
  theta += PI / 22;
  // Reposition ellipse if it goes off the screen
  if (loaderX > width + 5) {
    loaderX = -5;
  }
}
