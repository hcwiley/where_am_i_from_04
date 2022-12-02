import ddf.minim.*;
import ddf.minim.analysis.*;

Minim minim;
AudioPlayer song;
BeatDetect beat;
BeatListener bl;

boolean drawBeatText = false;

float kickSize, snareSize, hatSize;
long numBeats = 0;
int songIdx = 0;

// For loading animation
float loaderX, loaderY, theta;

ImageLoader drawingImages, paintingImages;
float imageFrameRate = 10;
float imageFrameRateDelta = 0.01;
int blittedFrameCount = 0;
int blittedOffset = 0;
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

boolean pauseLoop = false;
long startTime0 = 0;

long startLoad = 0;
long endLoad = 0;
void
setup()
{
  long start = millis();
  size(512, 512, P3D);
   fullScreen();
  frameRate(30);

  minim = new Minim(this);

  song = minim.loadFile(mp3Names[songIdx], 2048);
  // song.skip(30 * 1000);
  // a beat detection object that is FREQ_ENERGY mode that
  // expects buffers the length of song's buffer size
  // and samples captured at songs's sample rate
  beat = new BeatDetect(song.bufferSize(), song.sampleRate());
  beat.setSensitivity(20);
  kickSize = snareSize = hatSize = 16;
  // make a new beat listener, so that we won't miss any buffers for the
  // analysis
  bl = new BeatListener(beat, song);
  textFont(createFont("Helvetica", 16));
  textAlign(CENTER);

  int numImgs = 20000;
  int offset = 100;
  startLoad = millis();
  drawingImages = new ImageLoader("drawing", numImgs, 6, offset);
  paintingImages = new ImageLoader("painting", numImgs, 6, offset);
  drawingImages.checkLoadCount();
  paintingImages.checkLoadCount();
}

void
draw()
{
  if (pauseLoop) {
    return;
  }

  long start = millis();

  if (startTime0 == 0)
    startTime0 = start;

  // check if we are still loading images
  if (!song.isPlaying()) {
    if (drawingImages.checkLoadCount() == drawingImages.imgCount &&
        paintingImages.checkLoadCount() == paintingImages.imgCount) {
      if (endLoad == 0) {
        endLoad = millis();
        println("Loading took " + (endLoad - startLoad) + " ms");
      }
      drawingImages.applyFilter(INVERT);
      song.play();
    } else {
      // do some loading jazz
      println("Load count " +
              (float)drawingImages.checkLoadCount() / drawingImages.imgCount +
              "& " +
              (float)paintingImages.checkLoadCount() / paintingImages.imgCount);
      runLoaderAni();
      return;
    }
  }

  background(0);
  noTint();

  // beat.detect(song.mix);
  // if (beat.isOnset()) {
  //  numBeats++;
  //}

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
  drawingImages.drawImage(
    blittedFrameCount, 0, 0, width, height, 255, drawingOpacity);

  nextPaintingOpacity = constrain(nextPaintingOpacity, 0, 255);
  paintingOpacityDecay = constrain(paintingOpacityDecay, 0.0, 1.0);
  paintingOpacity = (int)round(
    lerp(paintingOpacity, (float)nextPaintingOpacity, paintingOpacityDecay));
  paintingOpacity = constrain(paintingOpacity, 0, 255);

  // blit the painting image
  paintingImages.drawImage(
    blittedFrameCount, 0, 0, width, height, 255, paintingOpacity);

  noTint();

  if (drawBeatText) {
    fill(55);

    textSize(kickSize);
    text("KICK", width / 4, height / 2);

    textSize(snareSize);
    text("SNARE", width / 2, height / 2);

    textSize(hatSize);
    text("HAT", 3 * width / 4, height / 2);

    kickSize = constrain(kickSize * 0.95, 16, 32);
    snareSize = constrain(snareSize * 0.95, 16, 32);
    hatSize = constrain(hatSize * 0.95, 16, 32);
  }

  long end = millis();

  // calculate elapsed time
  long elapsed = end - start;
  totalElapsed = end - startTime0;

  // println("totalElapsed: " + totalElapsed);

  blittedFrameCount =
    (int)round((float)totalElapsed / 1000.0f * imageFrameRate) + blittedOffset;

  if (frameCount % 100 == 0) {
    int randoJump = (int)random(30, 1000);
    println("bump blit frame by " + randoJump);
    blittedFrameCount += randoJump;
  }

  if (true) {
    // calculate beats per minute
    // float bps =
    //  (float)numBeats / ((float)totalElapsed / (float)1000.0 / (float)60.0);

    fill(0);
    rect(0, 0, 175, 50);
    fill(255);
    textAlign(LEFT);
    textSize(20);
    text("blit count: " + blittedFrameCount, 15, 15);
    text("frame count: " + frameCount, 15, 40);
  }
}

// Loading animation
void
runLoaderAni()
{
  // Only run when images are loading
  ellipse(loaderX, loaderY, 10, 10);
  loaderX += 2;
  loaderY = height / 2 + sin(theta) * (height / 3);
  theta += PI / 22;
  fill(map((float)loaderX * 1.8 % width, 0, 1.0, 0, 255));
  textAlign(LEFT);
  text(
    (millis() - startLoad) + " ms", (loaderX * 1.4 + 20) % width, loaderY + 40);
  // Reposition ellipse if it goes off the screen
  if (loaderX > width + 5) {
    loaderX = -5;
  }
}

void
keyPressed()
{
  // If the key is between 'A'(65) to 'Z' and 'a' to 'z'(122)
  if ((key >= 'A' && key <= 'Z') || (key >= 'a' && key <= 'z')) {
    switch (key) {
      case 'M':
      case 'm': {
        blittedOffset = (int)random(drawingImages.imgCount);
        break;
      }
      case 'R':
      case 'r': {
        blittedFrameCount = 0;
        song.skip(0);
        break;
      }
      case 'P':
      case 'p': {
        pauseLoop = !pauseLoop;
        if (pauseLoop) {
          song.pause();
        } else {
          // song.play();
        }
        break;
      }
      case 'i': {
        imageFrameRateDelta = 0.01;
        break;
      }
      case 'I': {
        imageFrameRate = 10;
        break;
      }
      default: {
        println("Not sure how to handle: " + key);
        break;
      }
    }
  } else {
    long numOffset = 48;
    if (key == CODED) {
      switch (keyCode) {
        case UP: {
          imageFrameRate+=imageFrameRateDelta;
          break;
        }
        case DOWN: {
          imageFrameRate-=imageFrameRateDelta;
          break;
        }
        case LEFT: {
          imageFrameRateDelta *= 0.9;
          break;
        }case RIGHT: {
          imageFrameRateDelta *= 1.1;
          break;
        }
      }
    }

    if (key <= numOffset + 8 || key >= numOffset) {
      long keyInt = key - 48; // parseInt(key);
      println("keyInt: " + keyInt);
      if (keyInt >= 0 && keyInt <= 8) {
        songIdx = (int)keyInt;
        song.pause();
        song = minim.loadFile(mp3Names[songIdx], 2048);
        bl = new BeatListener(beat, song);
        song.play();
      }
    }
  }
}
