import { Context, HTTPRequest } from '@aws-appsync/utils';

type ChatCompletionInput = {
    input: {
        prompt: string;
    };
}

export function request(ctx: Context<ChatCompletionInput>): HTTPRequest {
    const { input: { prompt } } = ctx.args;
    return {
        method: 'POST',
        resourcePath: '/v1/chat/completions',
        params: {
            headers: {
                'Authorization': 'Bearer <OPEN AI TOKEN>',
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                model: 'gpt-4',
                messages: [
                    { role: 'user', content: prompt }
                ]
            })
        }
    }
}

type HttpResponse = {
    statusCode: number;
    body: string;
}

type ChatCompletionResponse = {
    choices: {
        message: {
            role: string;
            content: string;
        };
    }[];
}

export function response(ctx: Context<never, never, never, never, HttpResponse>): string {
    // The response of the HTTP call
    const { statusCode, body } = ctx.result;
    if (statusCode !== 200) {
        util.error(body);
    }
    const result = JSON.parse(body) as ChatCompletionResponse;
    return result.choices[0].message.content;
}
