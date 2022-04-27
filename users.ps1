function CreateUser {
	param(
		[Parameter()]
		[string] $upn,
		[Parameter()]
		[string] $displayName,
		[Parameter()]
		[string] $groupName
        )

    $userObjectId = $(az ad user list --upn $upn --query "[0].objectId")

    if($userObjectId){
      Write-Host "Skip"
    } else {
      Write-Host "Create User"
        $userObjectId=$(az ad user create --display-name $displayName --password "!ecret0Qwertz" --user-principal-name $upn --query objectId -o tsv)
        az ad group member add --group $groupName --member-id $userObjectId
    }

	Write-Host "User configured: $upn $groupName"
}

# https://docs.microsoft.com/en-us/cli/azure/ad/group?view=azure-cli-latest#az-ad-group-create
$groupName = "Encom"
$groupObjectId=$(az ad group list --display-name Encom --query [0].objectId -o tsv)

if($groupObjectId){
    Write-Host "Skip Group"
  } else {
    Write-Host "Create Group"
      $groupObjectId=$(az ad group create --display-name $groupName --mail-nickname $groupName --query objectId -o tsv)
      az ad group member add --group $groupName --member-id $userObjectId
      #az ad group owner add --group $groupName --owner-object-id 
}
          
CreateUser "Kevin.Flynn@meyermarkusgmx.onmicrosoft.com" "Kevin Flynn" $groupName
CreateUser "Alan.Bradley@meyermarkusgmx.onmicrosoft.com" "Alan Bradley" $groupName
CreateUser "Ed.Dillinger@meyermarkusgmx.onmicrosoft.com" "Ed Dillinger" $groupName
CreateUser "Walter.Gibbs@meyermarkusgmx.onmicrosoft.com" "Walter Gibbs" $groupName

