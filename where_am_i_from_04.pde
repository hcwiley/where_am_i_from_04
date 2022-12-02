import ddf.minim.*;
import ddf.minim.analysis.*;

Minim minim;
AudioPlayer song;
AudioInput audioIn;
BeatDetect beat;
BeatListener bl;

// how images should be load. Should between ~10 and how ever many are in the
// drawing/ folder. NOTE: If you make this too high your computer will run out
// of memory and crash. Probably want it to MAX out around 5000, which will
// require ~16gb of RAM
int numImgs = 2000;
// how many images to offset into the drawing/ folder. Should be between 1 and
// numImgs
int imageStartOffset = 1;

// how fast the images playback
float imageFrameRate = 10;
// how much the arrow up/down changes the image frame rate
float imageFrameRateDelta = 0.1;

// Toggle on/off drawing the kick / snare / hat debug text
boolean drawBeatText = true;

// Which song to play when starting. Should be between 0 and the number of songs
// Songs a indexed starting at 0. there are numbers next to the original 9
int songIdx = 0;

// Toggle use the mic or list of songs
boolean useMic = true;

// clang-format off
// like to keep this vertical please!

String mp3Names[] = {
    "a_earsnake.mp3"              // 0
  , "b_disposablechurch.mp3"      // 1
  , "b_ghastlytask.mp3"           // 2
  , "c_earthrisehigh.mp3"         // 3
  , "c_musclememoryloss.mp3"      // 4
  , "c_soulcoat.mp3"              // 5
  , "c_stutterface_1122.mp3"      // 6
  , "c_thinlinedance.mp3"         // 7
  , "z_coleandthefliesb.mp3"      // 8

  // Add more songs here. Make sure to get the name right, and the comma at the beginning of the line
  // , "song_name.mp3"
  // new songs go ˯˯˯˯ here 

  
  // new songs go ^^^ here
};
// clang-format on

////////////////////////////////////////////////
// YOU SHOULD NOT NEED TO EDIT ANYTHING BELOW //
////////////////////////////////////////////////
ImageLoader drawingImages, paintingImages;

float kickSize, snareSize, hatSize;
// For loading animation
float loaderX, loaderY, theta;

boolean pauseLoop = false;
long startTime0 = 0;

long startLoad = 0;
long endLoad = 0;

int blittedFrameCount = 0;
int blittedOffset = 0;
long totalElapsed = 0;

int drawingOpacity = 0;
float drawingOpacityDecay = 0.1;

int paintingOpacity = 0;
float paintingOpacityDecay = 0.1;

void
setup()
{
  long start = millis();
  size(512, 512, P3D);
  // fullScreen();
  frameRate(30);

  minim = new Minim(this);

  if (songIdx >= mp3Names.length) {
    println("songIdx out of range. Should be between 0 and " +
            (mp3Names.length - 1));
    exit();
  }

  kickSize = snareSize = hatSize = 16;
  int audioBufferSize = 2048;
  int audioSampleRate = 44100;

  beat = new BeatDetect(audioBufferSize, audioSampleRate);

  if (useMic) {
    audioIn = minim.getLineIn(Minim.MONO, audioBufferSize, audioSampleRate);
    bl = new BeatListener(beat, audioIn);
    beat.setSensitivity(400);
  } else {
    song = minim.loadFile(mp3Names[songIdx], audioBufferSize);

    bl = new BeatListener(beat, song);
    beat.setSensitivity(20);
    // song.skip(30 * 1000);
  }

  textFont(createFont("Helvetica", 16));
  textAlign(CENTER);

  startLoad = millis();
  drawingImages = new ImageLoader("drawing", numImgs, 6, imageStartOffset);
  paintingImages = new ImageLoader("painting", numImgs, 6, imageStartOffset);
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
  if (useMic || !song.isPlaying()) {
    if (drawingImages.checkLoadCount() == drawingImages.imgCount &&
        paintingImages.checkLoadCount() == paintingImages.imgCount) {
      if (endLoad == 0) {
        endLoad = millis();
        println("Loading took " + (endLoad - startLoad) + " ms");
      }
      drawingImages.applyFilter(INVERT);
      if (!useMic)
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
    blittedOffset += randoJump;
  }

  if (true) {
    // calculate beats per minute
    // float bps =
    //  (float)numBeats / ((float)totalElapsed / (float)1000.0 / (float)60.0);

    fill(0);
    // rect(0, 0, 175, 50);
    fill(255);
    textAlign(LEFT);
    int txtSize = 15;
    textSize(txtSize);
    int textY = 15;
    // format to 2 decimal places
    text("blit rate: " + nf(imageFrameRate, 0, 2) +
           " blit Δ: " + nf(imageFrameRateDelta, 0, 2),
         15,
         textY += txtSize * 1.25);
    text("blit count: " + blittedFrameCount, 15, textY += txtSize * 1.25);
    text("frame count: " + frameCount, 15, textY += txtSize * 1.25);
  }
}

// Loading animation
void
runLoaderAni()
{
  // Only run when images are loading //<>// //<>//
  ellipse(loaderX, loaderY, 10, 10);
  loaderX += 2;
  loaderY = height / 2 + sin(theta) * (height / 3);
  theta += PI / 22;
  fill(map((float)loaderX * 1.8 % width, 0, 1.0, 0, 255));
  textAlign(LEFT);
  text((millis() - startLoad) + " ms",
       (loaderX * 1.4 + 20) % width,
       loaderY + 40); //<>//
  // Reposition ellipse if it goes off the screen
  if (loaderX > width + 5) {
    loaderX = -5;
  }
} //<>// //<>//

boolean
changeSong(int newSongIdx)
{
  if (!useMic) {
    if (newSongIdx >= 0 && newSongIdx <= mp3Names.length) {
      songIdx = newSongIdx;
      song.pause();
      song = minim.loadFile(mp3Names[songIdx], 2048);
      bl = new BeatListener(beat, song);
      song.play();
      println("Playing [" + songIdx + "]: " + mp3Names[songIdx]);
      return true;
    }
  }
  return false;
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
    println("Not a letter key: " + key);
    if (key == CODED) {
      switch (keyCode) {
        case UP: {
          imageFrameRate += imageFrameRateDelta;
          break;
        }
        case DOWN: {
          imageFrameRate -= imageFrameRateDelta;
          break; //<>// //<>//
        }
        case LEFT: {
          imageFrameRateDelta *= 0.9;
          break;
        }
        case RIGHT: {
          imageFrameRateDelta *= 1.2;
          break;
        }
      }
    } //<>//

    if (key == '-') {
      int newSongIdx = (songIdx - 1);
      if (newSongIdx < 0) {
        newSongIdx = mp3Names.length - 1; //<>// //<>//
      }
      changeSong(newSongIdx);
    } else if (key == '=') {
      int newSongIdx = (songIdx + 1);
      if (newSongIdx >= mp3Names.length) {
        newSongIdx = 0;
      }
      changeSong(newSongIdx);
    }

    // check for number keys
    int numOffset = 48;
    if (key <= numOffset + 9 || key >= numOffset) {
      int keyInt = key - 48;
      changeSong(keyInt);
    }
  }
}
