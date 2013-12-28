
// third-party
use bleep
import bleep

use deadlogger
import deadlogger/[Log, Logger]

// sdk
import math/Random
import structs/[HashMap]

BoomboxConfig: class {

    musicPath := "assets/ogg"
    sfxPath := "assets/wav"
    mute := false

    init: func

}

// a sound system :D
Boombox: class {

    // composition
    bleep: Bleep
    config := BoomboxConfig new()
    logger := static Log getLogger("boombox")

    // state
    samples := HashMap<String, Sample> new()
    currentMusic: String
    loops := 0

    new: static func -> This {
        try {
            return This new~private()
        } catch (e: Exception) {
            logger error("Couldn't load audio system because of: #{e formatMessage()}")
        }
        return DummyBoombox new()
    }

    init: func ~private {
        bleep = Bleep new()
        bleep onMusicStop(|| onMusicStops())
    }

    // Music code
    playMusic: func (name: String, loops := 0) {
        // abide by the mute
        if (config mute) return
        if (currentMusic == name) return

        _playMusic(name, loops)
        currentMusic = name
    }

    _playMusic: func (name: String, =loops) {
        bleep playMusic("%s/%s.ogg" format(config musicPath, name), loops)
    }

    setMute: func (mute: Bool) {
        config mute = mute
        if (mute) {
            bleep stopMusic()
        } else {
            if (currentMusic) {
                _playMusic(currentMusic, loops)
            }
        }
    }

    stopMusic: func {
        bleep stopMusic()
    }

    fadeMusic: func (millis: Int) {
        bleep fadeMusic(millis)
    }

    onMusicStops: func {
        currentMusic = null
    }

    musicPlays?: func -> Bool {
        bleep musicPlaying?()
    }

    musicPaused?: func -> Bool {
        bleep musicPaused?()
    }

    // SFX code
    playSound: func (name: String, loops := 0) {
        // abide by the mute
        if (config mute) return

        if (samples contains?(name)) {
            samples get(name) play(loops)
        } else {
            path := "%s/%s.wav" format(config sfxPath, name)
            sample := bleep loadSample(path)
            if (sample) {
                samples put(name, sample)
                sample play(loops)
            } else {
                logger warn("Couldn't load sfx %s", path)
            }
        }
    }

    playRandomSound: func (name: String, variants := 2, loops := 0) {
        variant := Random randInt(1, variants)
        playSound("%s%d" format(name, variant), loops)
    }

    destroy: func {
        bleep destroy()
    }

}

DummyBoombox: class extends Boombox {

    // do nothing
    init: func
    playMusic: func (name: String, loops := 0)
    onMusicStops: func
    musicPlays?: func -> Bool { false }
    playSound: func (name: String, loops := 0)
    destroy: func

}

