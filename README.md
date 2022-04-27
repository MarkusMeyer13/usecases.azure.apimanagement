# Azure API Management

Use Cases for Azure API Management and self-hosted gateway

## Prerequisites

Create demo users and groups in Azure Active Directory.

Prepare your enviroment with [Bicep](https://github.com/Azure/bicep) in order to deploy API Management with _main.bicep_.

## Self-hosted Gateway with Docker Desktop

Update _env.conf_ with values from API Management.

```docker
docker run -d -p 80:8080 -p 443:8081 --name EvaluationGateway --env-file env.conf mcr.microsoft.com/azure-api-management/gateway:latest

docker logs --follow EvaluationGateway
```

### Install self-hosted Gateway

[Docker Hub Image](https://hub.docker.com/_/microsoft-azure-api-management-gateway)  

[Additional Topics - Self-hosted Gateway](https://azure.github.io/apim-lab/apim-lab/10-additionalTopics/apimanagement-10-4-selfhostedgateway.html)  
[Deploying an Azure APIM Self-Hosted Gateway](https://soltisweb.com/blog/detail/2021-04-22-deployinganazureapimself-hostedgateway)  

[Install Gateway with Helm](https://github.com/Azure/api-management-self-hosted-gateway)

## My On-Premise environment

There's a webserver which returns sample JSON and XML documents:  
[SOAP Response](http://192.0.0.0:9099/numbers.xml)
[REST Response](http://192.0.0.0:9099/tinyurl.json)

## API Evaluation

### OpenApi

```yaml
openapi: 3.0.1
info:
  title: Evaluation
  description: ''
  version: '1.0'
servers:
  - url: 'https://demoapiservicey27itmeb4cf7q.azure-api.net/evaluation'
paths:
  /hello:
    get:
      summary: hello
      description: hello
      operationId: hello
      responses:
        '200':
          description: OK
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/HelloGet200ApplicationJsonResponse'
              example:
                hello: world
        '400':
          description: Bad Request
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Get400ApplicationJsonResponse'
              example:
                status: error
  /time:
    get:
      summary: time
      description: time
      operationId: time
      responses:
        '200':
          description: OK
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/TimeGet200ApplicationJsonResponse'
              example:
                hello: world
        '400':
          description: Bad Request
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Get400ApplicationJsonResponse'
              example:
                status: error
  /time-cached:
    get:
      summary: time cached
      description: time cached
      operationId: time-cached
      responses:
        '200':
          description: OK
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/TimeGet200ApplicationJsonResponse'
              example:
                hello: world
        '400':
          description: Bad Request
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Get400ApplicationJsonResponse'
              example:
                status: error
  /hello-time:
    get:
      summary: hello time
      description: hello time
      operationId: hello-time
      responses:
        '200':
          description: OK
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/HelloTimeGet200ApplicationJsonResponse'
              example:
                hello: world
        '400':
          description: Bad Request
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Get400ApplicationJsonResponse'
              example:
                status: error
components:
  schemas:
    Get400ApplicationJsonResponse:
      type: object
      properties:
        status:
          type: string
          example: error
    HelloGet200ApplicationJsonResponse:
      type: object
      properties:
        hello:
          type: string
          example: world
    TimeGet200ApplicationJsonResponse:
      type: object
      properties:
        time:
          type: string
          format: datetime
          example: '2022-04-26T09:50:23.5214745+00:00'
    HelloTimeGet200ApplicationJsonResponse:
      type: object
      properties:
        hello:
          type: string
          example: world
        time:
          type: string
          format: datetime
          example: '2022-04-26T09:50:23.5214745+00:00'
  securitySchemes:
    apiKeyHeader:
      type: apiKey
      name: Ocp-Apim-Subscription-Key
      in: header
    apiKeyQuery:
      type: apiKey
      name: subscription-key
      in: query
security:
  - apiKeyHeader: []
  - apiKeyQuery: []

```

### GET /hello

```xml
<policies>
    <inbound>
        <base />
        <mock-response status-code="200" content-type="application/json" />
    </inbound>
    <backend>
        <base />
    </backend>
    <outbound>
        <base />
    </outbound>
    <on-error>
        <base />
    </on-error>
</policies>
```

### GET /hello-time

```xml
<policies>
    <inbound>
        <base />
        <send-request mode="new" response-variable-name="helloResponse" timeout="120" ignore-error="false">
            <set-url>@{
                return context.Request.Url.ToString().Replace("hello-time", "hello");
            }</set-url>
            <set-method>GET</set-method>
            <set-header name="Ocp-Apim-Subscription-Key" exists-action="override">
                <value>{{EvaluationApiKey}}</value>
            </set-header>
            <set-header name="Content-Type" exists-action="override">
                <value>application/json</value>
            </set-header>
            <set-header name="Ocp-Apim-Trace" exists-action="override">
                <value>true</value>
            </set-header>
        </send-request>
        <rewrite-uri template="/time" />
    </inbound>
    <backend>
        <base />
    </backend>
    <outbound>
        <base />
        <choose>
            <when condition="@(((IResponse)context.Variables["helloResponse"]).StatusCode == 200 && context.Response.StatusCode == 200)">
                <set-body>@{
                    var body = context.Response.Body.As<JObject>(true);
                    var helloWorldBody =  ((IResponse)context.Variables["helloResponse"]).Body.As<JObject>();
                    body["hello"] = helloWorldBody["hello"];
                    return body.ToString();
                }</set-body>
            </when>
            <otherwise>
                <return-response>
                    <set-status code="400" reason="Bad request" />
                    <set-header name="Content-Type" exists-action="override">
                        <value>application/json</value>
                    </set-header>
                    <set-body>@{
                        JObject response = new JObject();
                        response.Add("message", "error");
                        return response.ToString();
                    }</set-body>
                </return-response>
            </otherwise>
        </choose>
    </outbound>
    <on-error>
        <base />
    </on-error>
</policies>
```

### GET /time

```xml
<policies>
    <inbound>
        <base />
        <return-response>
            <set-status code="200" reason="OK" />
            <set-body>@{
                var message = new JObject();
                message["time"] = DateTime.Now;
                return message.ToString();
            }</set-body>
        </return-response>
    </inbound>
    <backend>
        <base />
    </backend>
    <outbound>
        <base />
    </outbound>
    <on-error>
        <base />
    </on-error>
</policies>
```

### GET /time-cached

```xml
<policies>
    <inbound>
        <base />
        <cache-lookup vary-by-developer="false" vary-by-developer-groups="false" must-revalidate="true" downstream-caching-type="public">
            <vary-by-header>header</vary-by-header>
            <vary-by-query-parameter>query</vary-by-query-parameter>
        </cache-lookup>
        <rewrite-uri template="/time" />
    </inbound>
    <backend>
        <forward-request timeout="10" />
    </backend>
    <outbound>
        <base />
        <cache-store duration="10" cache-response="true" />
    </outbound>
    <on-error>
        <base />
    </on-error>
</policies>
```
