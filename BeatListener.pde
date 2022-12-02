
class BeatListener implements AudioListener
{
private
  BeatDetect beat;
private
  AudioPlayer source;
  AudioInput sourceInput;

  BeatListener(BeatDetect beat, AudioPlayer source)
  {
    this.source = source;
    this.source.addListener(this);
    this.beat = beat;
  }

  BeatListener(BeatDetect beat, AudioInput source)
  {
    this.sourceInput = source;
    this.sourceInput.addListener(this);
    this.beat = beat;
  }

  void samples(float[] samps)
  {
    if (source != null) {
      beat.detect(source.mix);
    } else {
      beat.detect(sourceInput.mix);
    }
    // beat.detect(source.mix);
  }

  void samples(float[] sampsL, float[] sampsR)
  {
    if (source != null) {
      beat.detect(source.mix);
    } else {
      beat.detect(sourceInput.mix);
    }
    // beat.detect(source.mix);
  }
}
