import { App, CfnOutput, Duration, Expiration, Stack, StackProps } from 'aws-cdk-lib';
import { AuthorizationType, Code, FunctionRuntime, GraphqlApi, SchemaFile } from 'aws-cdk-lib/aws-appsync';
import { Construct } from 'constructs';
import * as p from 'path';

export class MyStack extends Stack {
  constructor(scope: Construct, id: string, props: StackProps = {}) {
    super(scope, id, props);

    const graphqlApi = new GraphqlApi(this, 'Api', {
      name: 'billion-dollar-goat',
      schema: SchemaFile.fromAsset(p.join(__dirname, 'schema.graphql')),
      authorizationConfig: {
        defaultAuthorization: {
          authorizationType: AuthorizationType.API_KEY,
          apiKeyConfig: {
            expires: Expiration.after(Duration.days(365)),
          }
        }
      }
    });

    new CfnOutput(this, 'GraphQlApi', {
      value: graphqlApi.graphqlUrl,
    });

    new CfnOutput(this, 'GraphQlApiKey', {
      value: graphqlApi.apiKey!,
    });

    const httpDataSource = graphqlApi.addHttpDataSource('HttpDataSource', 'https://api.openai.com');

    httpDataSource.createResolver('Query.completeChat', {
      typeName: 'Query',
      fieldName: 'completeChat',
      runtime: FunctionRuntime.JS_1_0_0,
      code: Code.fromAsset(p.join(__dirname, 'Query.completeChat.js')),
    });

  }
}

const app = new App();

new MyStack(app, 'BillionDollarGoat', {
  env: {
    account: process.env.CDK_DEFAULT_ACCOUNT,
    region: process.env.CDK_DEFAULT_REGION,
  }
});

app.synth();