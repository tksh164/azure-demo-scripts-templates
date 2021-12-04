@{

    PreferredLanguage = 'ja-JP'
    SystemLocale = 'ja-JP'
    TimeZoneId = 'Tokyo Standard Time'  # Get from [System.TimeZoneInfo]::GetSystemTimeZones()
    LocationGeoId = 122  # Japan
    LanguagePack = @{
        # Reference:
        # - Cannot configure a language pack for Windows Server 2019 Desktop Experience
        #   https://docs.microsoft.com/en-us/troubleshoot/windows-server/shell-experience/cannot-configure-language-pack-windows-server-desktop-experience
        IsoFileUri               = 'https://software-download.microsoft.com/download/pr/17763.1.180914-1434.rs5_release_SERVERLANGPACKDVD_OEM_MULTI.iso'  # for WS2019
        CabFileName              = 'Microsoft-Windows-Server-Language-Pack_x64_ja-jp.cab'
        OffsetToCabFileInIsoFile = 0x3BD26800
        CabFileSize              = 62015873
        CabFileHash              = 'B562ECD51AFD32DB6E07CB9089691168C354A646'
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
