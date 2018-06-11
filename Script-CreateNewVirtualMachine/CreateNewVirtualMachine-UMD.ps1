#Login-AzureRmAccount


##
## 新しいリソース グループの作成
##

$resourceGroupName = 'Demo-ARM-PowerShell-UMD'
$location = 'japaneast'

New-AzureRmResourceGroup -Name $resourceGroupName -Location $location


##
## 新しい仮想ネットワークの作成
##

$subnetName = 'default'
$vnetName = 'Main-vnet'

# サブネット構成の作成
$subnet = New-AzureRmVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix '10.0.64.0/24'

# 仮想ネットワークの作成
$vnet = New-AzureRmVirtualNetwork -Name $vnetName -ResourceGroupName $resourceGroupName -Location $location -AddressPrefix '10.0.0.0/16' -Subnet $subnet

# サブネット構成の取得
$subnet = Get-AzureRmVirtualNetworkSubnetConfig -Name $subnetName -VirtualNetwork $vnet


##
## 新しいパブリック IP アドレスの作成
##

$pipName = 'vm1-ip'
$domainLabel = 'vm1ipumd10121911'

# 新しいパブリック IP アドレスのドメイン ラベルが使用可能かどうか検証
# 結果が True であれば使用可能なドメイン ラベル
Test-AzureRmDnsAvailability -Location $location -DomainNameLabel $domainLabel

$pip = New-AzureRmPublicIpAddress -ResourceGroupName $resourceGroupName -Name $pipName -Location $location -AllocationMethod Dynamic -DomainNameLabel $domainLabel


##
## 新しいネットワーク インターフェースの作成
##

$nic = New-AzureRmNetworkInterface -ResourceGroupName $resourceGroupName -Name 'vm1-nic' -Subnet $subnet -Location $location -PublicIpAddress $pip -PrivateIpAddress '10.0.64.4'


##
## 新しいストレージ アカウントの作成
##

$storageAccountName = 'vmdisksa0909'

# ストレージ アカウント名が使用可能かどうか検証
# 検証結果の NameAvailable が True であれば使用可能な名前
Get-AzureRmStorageAccountNameAvailability -Name $storageAccountName

New-AzureRmStorageAccount -ResourceGroupName $resourceGroupName -Location $location -Name $storageAccountName -SkuName Standard_LRS


##
## イメージ情報の取得
##

# PublisherName の特定
#Get-AzureRmVMImagePublisher -Location $location | Where-Object -Property 'PublisherName' -Like -Value '*WindowsServer*'

# Offer の特定
#Get-AzureRmVMImageOffer -Location $location -PublisherName 'MicrosoftWindowsServer'

# SKU の特定
#Get-AzureRmVMImageSku -Location $location -PublisherName 'MicrosoftWindowsServer' -Offer 'WindowsServer'

# Version の特定
# 最新バージョンを使用する場合には、Set-AzureRmVMSourceImage で latest を指定可能
#Get-AzureRmVMImage -Location $location -PublisherName 'MicrosoftWindowsServer' -Offer 'WindowsServer' -Skus '2016-Datacenter'

$publisherName = 'MicrosoftWindowsServer'
$offer = 'WindowsServer'
$sku = '2016-Datacenter-smalldisk'


##
## 新しい VM の構成情報を作成
##

$vmName = 'vm1'
$vmSize = 'Standard_A1_v2'
$vmAdmincredential = Get-Credential  # 仮想マシンの管理者アカウントの資格情報を対話的に設定

# OS ディスク VHD 配置先の URI を作成
$osDiskVhdName = 'vm1-osdisk.vhd'
$osDiskVhdUri = ('https://{0}.blob.core.windows.net/vhds/{1}' -f $storageAccountName, $osDiskVhdName)

# 新しい VM 構成の作成
$vmConfig = New-AzureRmVMConfig -VMName $vmName -VMSize $vmSize |

    # OS パラメータの設定
    Set-AzureRmVMOperatingSystem -Windows -ComputerName $vmName -Credential $vmAdmincredential -ProvisionVMAgent -EnableAutoUpdate |

    # VM の元イメージの指定
    Set-AzureRmVMSourceImage -PublisherName $publisherName -Offer $offer -Skus $sku -Version latest |

    # OS ディスクの設定
    Set-AzureRmVMOSDisk -Name $osDiskVhdName -VhdUri $osDiskVhdUri -CreateOption FromImage -Caching ReadWrite |

    # VM にネットワーク インターフェースを追加
    Add-AzureRmVMNetworkInterface -Id $nic.Id


##
## VM の作成
##

New-AzureRmVM -ResourceGroupName $resourceGroupName -Location $location -VM $vmConfig -Verbose
