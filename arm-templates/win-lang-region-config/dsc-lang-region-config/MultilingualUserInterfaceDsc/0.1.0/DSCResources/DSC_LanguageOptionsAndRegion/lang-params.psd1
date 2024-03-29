# Reference:
# - Default Input Profiles (Input Locales) in Windows
#   https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/default-input-locales-for-windows-language-packs

@{
    # Windows Server 2022
    '10.0.20348' = @{
        # Reference:
        # - Evaluation Center
        #   https://www.microsoft.com/en-us/evalcenter/evaluate-windows-server-2022
        'LangPackIsoUri' = 'https://software-static.download.prss.microsoft.com/pr/download/20348.1.210507-1500.fe_release_amd64fre_SERVER_LOF_PACKAGES_OEM.iso'

        'Languages' = @{
            'en-US' = @{
                LanguagePack = @{
                    PackageName              = 'Microsoft-Windows-Server-LanguagePack-Package~31bf3856ad364e35~amd64~en-US~10.0.20348.*'
                    CabFileName              = 'Microsoft-Windows-Server-Language-Pack_x64_en-us.cab'
                    OffsetToCabFileInIsoFile = 0xE7886800L
                    CabFileSize              = 40382505
                    CabFileHash              = '380036234F05EAEC1153D0306B0A829FE8CE84E0'
                }
                CapabilityNames = @{
                    Minimum = @(
                        'Language.Basic~~~en-US~0.0.1.0',
                        'Language.OCR~~~en-US~0.0.1.0'
                    )
                    Additional = @(
                        'Language.Handwriting~~~en-US~0.0.1.0',
                        'Language.Speech~~~en-US~0.0.1.0',
                        'Language.TextToSpeech~~~en-US~0.0.1.0'
                    )
                }
                InputLanguageID = '0409:00000409'
            }
            'ja-JP' = @{
                LanguagePack = @{
                    PackageName              = 'Microsoft-Windows-Server-LanguagePack-Package~31bf3856ad364e35~amd64~ja-JP~10.0.20348.*'
                    CabFileName              = 'Microsoft-Windows-Server-Language-Pack_x64_ja-jp.cab'
                    OffsetToCabFileInIsoFile = 0x107D35800L
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
            'fr-FR' = @{
                LanguagePack = @{
                    PackageName              = 'Microsoft-Windows-Server-LanguagePack-Package~31bf3856ad364e35~amd64~fr-FR~10.0.20348.*'
                    CabFileName              = 'Microsoft-Windows-Server-Language-Pack_x64_fr-fr.cab'
                    OffsetToCabFileInIsoFile = 0xF8DD8000L
                    CabFileSize              = 52561156
                    CabFileHash              = '2087B0A81D20386F458D4BC285634F88ABFD92C0'
                }
                CapabilityNames = @{
                    Minimum = @(
                        'Language.Basic~~~fr-FR~0.0.1.0'
                        'Language.OCR~~~fr-FR~0.0.1.0'
                    )
                    Additional = @(
                        'Language.Handwriting~~~fr-FR~0.0.1.0',
                        'Language.Speech~~~fr-FR~0.0.1.0',
                        'Language.TextToSpeech~~~fr-FR~0.0.1.0'
                    )
                }
                InputLanguageID = '040c:0000040c'
            }
            'ko-KR' = @{
                LanguagePack = @{
                    PackageName              = 'Microsoft-Windows-Server-LanguagePack-Package~31bf3856ad364e35~amd64~ko-KR~10.0.20348.*'
                    CabFileName              = 'Microsoft-Windows-Server-Language-Pack_x64_ko-kr.cab'
                    OffsetToCabFileInIsoFile = 0x10B0D5000L
                    CabFileSize              = 53421375
                    CabFileHash              = 'C7A93C0FD421622C051ECABBAE6FC7D9B6598DE5'
                }
                CapabilityNames = @{
                    Minimum = @(
                        'Language.Basic~~~ko-KR~0.0.1.0',
                        'Language.Fonts.Kore~~~und-KORE~0.0.1.0',
                        'Language.OCR~~~ko-KR~0.0.1.0'
                    )
                    Additional = @(
                        'Language.Handwriting~~~ko-KR~0.0.1.0',
                        'Language.TextToSpeech~~~ko-KR~0.0.1.0'
                    )
                }
                InputLanguageID = '0412:{A028AE76-01B1-46C2-99C4-ACD9858AE02F}{B5FE1F02-D5F2-4445-9C03-C568F23C99A1}'
            }
        }
    }

    # Windows Server 2019
    '10.0.17763' = @{
        # Reference:
        # - Cannot configure a language pack for Windows Server 2019 Desktop Experience
        #   https://docs.microsoft.com/en-us/troubleshoot/windows-server/shell-experience/cannot-configure-language-pack-windows-server-desktop-experience
        'LangPackIsoUri' = 'https://software-static.download.prss.microsoft.com/pr/download/17763.1.180914-1434.rs5_release_SERVERLANGPACKDVD_OEM_MULTI.iso'

        'Languages' = @{
            'en-US' = @{
                LanguagePack = @{
                    PackageName              = 'Microsoft-Windows-Server-LanguagePack-Package~31bf3856ad364e35~amd64~en-US~10.0.17763.*'
                    CabFileName              = 'Microsoft-Windows-Server-Language-Pack_x64_en-us.cab'
                    OffsetToCabFileInIsoFile = 0x1780D000L
                    CabFileSize              = 41441411
                    CabFileHash              = 'B10C36225B9AFB503383FEA94A0D16FE4191CA37'
                }
                CapabilityNames = @{
                    Minimum = @(
                        'Language.Basic~~~en-US~0.0.1.0',
                        'Language.OCR~~~en-US~0.0.1.0'
                    )
                    Additional = @(
                        'Language.Handwriting~~~en-US~0.0.1.0',
                        'Language.Speech~~~en-US~0.0.1.0',
                        'Language.TextToSpeech~~~en-US~0.0.1.0'
                    )
                }
                InputLanguageID = '0409:00000409'
            }
            'ja-JP' = @{
                LanguagePack = @{
                    PackageName              = 'Microsoft-Windows-Server-LanguagePack-Package~31bf3856ad364e35~amd64~ja-JP~10.0.17763.*'
                    CabFileName              = 'Microsoft-Windows-Server-Language-Pack_x64_ja-jp.cab'
                    OffsetToCabFileInIsoFile = 0x3BD26800L
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
            'fr-FR' = @{
                LanguagePack = @{
                    PackageName              = 'Microsoft-Windows-Server-LanguagePack-Package~31bf3856ad364e35~amd64~fr-FR~10.0.17763.*'
                    CabFileName              = 'Microsoft-Windows-Server-Language-Pack_x64_fr-fr.cab'
                    OffsetToCabFileInIsoFile = 0x2ADB2000L
                    CabFileSize              = 60331188
                    CabFileHash              = '02CBE6DC0302F15AFBBC9159E5A1AE81AAC86804'
                }
                CapabilityNames = @{
                    Minimum = @(
                        'Language.Basic~~~fr-FR~0.0.1.0'
                        'Language.OCR~~~fr-FR~0.0.1.0'
                    )
                    Additional = @(
                        'Language.Handwriting~~~fr-FR~0.0.1.0',
                        'Language.Speech~~~fr-FR~0.0.1.0',
                        'Language.TextToSpeech~~~fr-FR~0.0.1.0'
                    )
                }
                InputLanguageID = '040c:0000040c'
            }
            'ko-KR' = @{
                LanguagePack = @{
                    PackageName              = 'Microsoft-Windows-Server-LanguagePack-Package~31bf3856ad364e35~amd64~ko-KR~10.0.17763.*'
                    CabFileName              = 'Microsoft-Windows-Server-Language-Pack_x64_ko-kr.cab'
                    OffsetToCabFileInIsoFile = 0x3F84B800L
                    CabFileSize              = 62974463
                    CabFileHash              = '1370BBE78210CDF6D8156D9125C0D17C05607D82'
                }
                CapabilityNames = @{
                    Minimum = @(
                        'Language.Basic~~~ko-KR~0.0.1.0',
                        'Language.Fonts.Kore~~~und-KORE~0.0.1.0',
                        'Language.OCR~~~ko-KR~0.0.1.0'
                    )
                    Additional = @(
                        'Language.Handwriting~~~ko-KR~0.0.1.0',
                        'Language.TextToSpeech~~~ko-KR~0.0.1.0'
                    )
                }
                InputLanguageID = '0412:{A028AE76-01B1-46C2-99C4-ACD9858AE02F}{B5FE1F02-D5F2-4445-9C03-C568F23C99A1}'
            }
        }
    }
}
