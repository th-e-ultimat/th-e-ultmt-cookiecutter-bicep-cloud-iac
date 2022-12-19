targetScope = 'subscription'

param environmentType string
param prefix string

//N.B: Naming standard has to be consistent for the deployment to work
//TODO: enforce this by using reusable module

var apiManagementResourceGroupName = '${prefix}-rg-api-${environmentType}'
var apiManagementName = '${prefix}-apim-api-${environmentType}'

var financialRiskDalName = '${prefix}-func-financialrisk-dal-${environmentType}'
var financialRiskDalResorceGroupName = '${prefix}-rg-financialrisk-${environmentType}'

var calculatorDalName = '${prefix}-func-calculator-dal-${environmentType}'
var calculatorResorceGroupName = '${prefix}-rg-calculator-${environmentType}'

var userDalName = '${prefix}-func-user-dal-${environmentType}'
var userResorceGroupName = '${prefix}-rg-user-${environmentType}'

var productDalName = '${prefix}-func-product-dal-${environmentType}'
var productResorceGroupName = '${prefix}-rg-product-${environmentType}'

var crmDalName = '${prefix}-func-crm-dal-${environmentType}'
var crmResorceGroupName = '${prefix}-rg-crm-${environmentType}'

var articleDalName = '${prefix}-func-article-dal-${environmentType}'
var articleResorceGroupName = '${prefix}-rg-article-${environmentType}'

var deviceDalName = '${prefix}-func-device-dal-${environmentType}'
var deviceResorceGroupName = '${prefix}-rg-device-${environmentType}'

var documentDalName = '${prefix}-func-document-dal-${environmentType}'
var documentResorceGroupName = '${prefix}-rg-document-${environmentType}'

module functionAppModule 'modules/api/functionapp/main.bicep' = {
  name: 'api-functionapp'
  scope: resourceGroup(apiManagementResourceGroupName)
  params: {
    userDalName : userDalName
    userResorceGroupName : userResorceGroupName
    apiManagementName: apiManagementName
    financialRiskDalName: financialRiskDalName
    financialRiskDalResorceGroupName: financialRiskDalResorceGroupName
    calculatorDalName: calculatorDalName
    calculatorResorceGroupName: calculatorResorceGroupName
    productDalName: productDalName
    productResorceGroupName: productResorceGroupName
    crmDalName: crmDalName
    crmResorceGroupName: crmResorceGroupName
    articleDalName: articleDalName
    articleResorceGroupName: articleResorceGroupName
    deviceDalName: deviceDalName
    deviceResorceGroupName: deviceResorceGroupName
    documentDalName: documentDalName
    documentResorceGroupName: documentResorceGroupName
  }
}
