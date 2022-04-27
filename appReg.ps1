# https://docs.microsoft.com/en-us/azure/api-management/api-management-howto-aad

# Grant permissions for app:
$subId = "Your Azure subscription ID" #e.g. "1fb8fadf-03a3-4253-8993-65391f432d3a"
$tenantId = "Your Azure AD Tenant or Organization ID" #e.g. 0e054eb4-e5d0-43b8-ba1e-d7b5156f6da8"
$appObjectID = "Application Object ID that has been registered in AAD" #e.g. "2215b54a-df84-453f-b4db-ae079c0d2619"

#Login and Set the Subscription
az login
az account set --subscription $subId

#Assign the following permissions: Microsoft Graph Delegated Permission: User.Read, Microsoft Graph Application Permission: Directory.ReadAll,  Azure Active Directory Graph Application Permission: Directory.ReadAll (legacy)
az rest --method PATCH --uri "https://graph.microsoft.com/v1.0/$($tenantId)/applications/$($appObjectID)" --body "{'requiredResourceAccess':[{'resourceAccess': [{'id': 'e1fe6dd8-ba31-4d61-89e7-88639da4683d','type': 'Scope'},{'id': '7ab1d382-f21e-4acd-a863-ba3e13f7da61','type': 'Role'}],'resourceAppId': '00000003-0000-0000-c000-000000000000'},{'resourceAccess': [{'id': '5778995a-e1bf-45b8-affa-663a9f3f4d04','type': 'Role'}], 'resourceAppId': '00000002-0000-0000-c000-000000000000'}]}"
