##
## Windows 10 での PowerShell を使用したポイント対サイト接続の証明書の生成とエクスポート
## https://docs.microsoft.com/ja-jp/azure/vpn-gateway/vpn-gateway-certificates-point-to-site
##

##
## 自己署名ルート証明書の作成
##

$rootCert = New-SelfSignedCertificate -Subject 'CN=VNetJapanEastRootCert' -CertStoreLocation 'Cert:\CurrentUser\My' -Type Custom -KeySpec Signature -HashAlgorithm sha256 -KeyLength 2048 -KeyUsageProperty Sign -KeyUsage CertSign -KeyExportPolicy Exportable

# 既存証明書の取得
#$rootCert = (Get-ChildItem -Path 'Cert:\CurrentUser\My\11F8F2692769D1CD44F937482BC0506E25F33C6C')


##
## ルート証明書 (公開キー) を Azure にアップロード
##

# ルート証明書 (公開キー) を Base64 でエンコードしたテキスト データを取得
$rootCertBase64 = [System.Convert]::ToBase64String($rootCert.RawData)

# ルート証明書 (公開キー) を Azure にアップロード
$p2sRootCert = New-AzureRmVpnClientRootCertificate -Name 'VNetJapanEastRootCert' -PublicCertData $rootCertBase64
Add-AzureRmVpnClientRootCertificate -ResourceGroupName 'AzureForIaaS-RG' -VirtualNetworkGatewayName 'IaaSCloudNetJPEastGW' -VpnClientRootCertificateName $p2sRootCert.Name -PublicCertData $p2sRootCert.PublicCertData

# Azure Portal から操作を行う場合は、Base64 でエンコードしたテキスト データをクリップ ボードにコピーしてポータル上で入力する
#$rootCertBase64 | clip


##
## クライアント証明書の作成
##

#
# クライアント証明書を作成
#
# Reference:
#
#   IX509ExtensionEnhancedKeyUsage interface
#   https://msdn.microsoft.com/en-us/library/windows/desktop/aa378132(v=vs.85).aspx
#
#   拡張キー用途:
#     XCN_OID_ENHANCED_KEY_USAGE (2.5.29.37)
#     Enhanced Key Usage
#
#   クライアント認証用途:
#     XCN_OID_PKIX_KP_CLIENT_AUTH (1.3.6.1.5.5.7.3.2)
#     The certificate can be used for authenticating a client.
#
New-SelfSignedCertificate -Signer $rootCert -Subject 'CN=VNetJapanEastClientCert' -CertStoreLocation 'Cert:\CurrentUser\My' -Type Custom -TextExtension @('2.5.29.37={text}1.3.6.1.5.5.7.3.2') -KeySpec Signature -HashAlgorithm sha256 -KeyLength 2048 -KeyExportPolicy Exportable



##
## ルート証明書 (公開キー) をファイルにエクスポート
##

$rootCert = Get-ChildItem -LiteralPath 'Cert:\CurrentUser\My' | Where-Object -Property 'Subject' -EQ -Value 'CN=VNetJapanEastRootCert'
Export-Certificate -Cert $rootCert.PSPath -Type CERT -FilePath 'C:\Temp\RootCert.cer'


##
## クライアント証明書 (秘密キー含む) をファイルにエクスポート
##

$clientCert = Get-ChildItem -LiteralPath 'Cert:\CurrentUser\My' | Where-Object -Property 'Subject' -EQ -Value 'CN=VNetJapanEastClientCert'
$password = Get-Credential -Message 'クライアント証明書 (秘密キー含む) を保護するためのパスワードを入力します。' -UserName '(入力不要)'
Export-PfxCertificate -Cert $clientCert.PSPath -Password $password.Password -FilePath 'C:\Temp\ClientCert.pfx'
