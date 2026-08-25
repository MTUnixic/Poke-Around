package backend.util.grig.audio;

import tink.core.Error;

class PortAudioHelper
{
    private static var nameApiMapping = [
        'ALSA'                      => backend.util.grig.audio.Api.Alsa,
        'ASIO'                      => backend.util.grig.audio.Api.WindowsASIO,
        'Core Audio'                => backend.util.grig.audio.Api.MacOSCore,
        'Windows DirectSound'       => backend.util.grig.audio.Api.WindowsDS,
        'JACK Audio Connection Kit' => backend.util.grig.audio.Api.Jack,
        'OSS'                       => backend.util.grig.audio.Api.Oss,
        'Windows WASAPI'            => backend.util.grig.audio.Api.WindowsWASAPI,
        'Windows WDM-KS'            => backend.util.grig.audio.Api.WindowsWDMKS,
        'MME'                       => backend.util.grig.audio.Api.WindowsMME,
        'Unspecified'               => backend.util.grig.audio.Api.Unspecified,
    ];

    public static function apiFromName(name:String):Api
    {
        if (nameApiMapping.exists(name)) return nameApiMapping[name];
        throw new Error(InternalError, 'Unknown api: $name');
    }

    public static function nameFromApi(api:Api):String
    {
        for (name in nameApiMapping.keys()) {
            if (nameApiMapping[name] == api) return name;
        }
        throw new Error(InternalError, 'Unknown api: $api');
    }
}