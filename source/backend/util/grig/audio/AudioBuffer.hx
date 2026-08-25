package backend.util.grig.audio;

#if (js && !nodejs && !heaps)
typedef AudioBuffer<T> = backend.util.grig.audio.js.webaudio.AudioBuffer;
#elseif python
typedef AudioBuffer<T> = backend.util.grig.audio.python.AudioBuffer;
#else

@:forward
@:generic
abstract AudioBuffer<T:Float>(AudioBufferData<T>) from AudioBufferData<T> to AudioBufferData<T>
{
    public inline function new(numChannels:Int, numSamples:Int, sampleRate:Float) {
        this = new AudioBufferData<T>(numChannels, numSamples, sampleRate);
    }

    @:arrayAccess
    public inline function get(i:Int):AudioChannel<T> {
        return this.get(i);
    }
}

#end