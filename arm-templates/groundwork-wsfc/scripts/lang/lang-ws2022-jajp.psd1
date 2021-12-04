@{

    PreferredLanguage = 'ja-JP'
    SystemLocale = 'ja-JP'
    TimeZoneId = 'Tokyo Standard Time'  # Get from [System.TimeZoneInfo]::GetSystemTimeZones()
    LocationGeoId = 122  # Japan
    LanguagePack = @{
        # Reference:
        # - Evaluation Center
        #   https://www.microsoft.com/en-us/evalcenter/evaluate-windows-server-2022
        #   In addition to your trial experience of Windows Server 2022, you can more easily add and manage languages and Features on Demand with the new Languages and Optional Features ISO. Download this ISO.
        IsoFileUri               = 'https://software-download.microsoft.com/download/sg/20348.1.210507-1500.fe_release_amd64fre_SERVER_LOF_PACKAGES_OEM.iso'  # for WS2022
        CabFileName              = 'Microsoft-Windows-Server-Language-Pack_x64_ja-jp.cab'
        OffsetToCabFileInIsoFile = 0x107D35800
        CabFileSize              = 54130307
        CabFileHash              = '298667B848087EA1377F483DC15597FD5F38A492'
    }
    CapabilityNames = @{
        Minimum = @(
            'Language.Basic~~~ja-JP~0.0.1.0',
            'Language.Fonts.Jpan~~~und-JPAN~0.0.1.0',
            'Language.OCR~~~ja-JP~0.0.1.0'
        )
        Additional = @(
            'Language.Handwriting~~~ja-JP~0.0.1.0',
            'Language.Speech~~~ja-JP~0.0.1.0',
            'Language.TextToSpeech~~~ja-JP~0.0.1.0'
        )
    }
    InputLanguageID = '0411:{03B5835F-F03C-411B-9CE2-AA23E1171E36}{A76C93D9-5523-4E90-AAFA-4DB112F9AC76}'
}
