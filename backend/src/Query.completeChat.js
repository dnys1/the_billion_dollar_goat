// src/Query.completeChat.ts
function request(ctx) {
  const { input: { prompt } } = ctx.args;
  return {
    method: "POST",
    resourcePath: "/v1/chat/completions",
    params: {
      headers: {
        "Authorization": "Bearer <OPEN AI TOKEN>",
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        model: "gpt-4",
        messages: [
          { role: "user", content: prompt }
        ]
      })
    }
  };
}
function response(ctx) {
  const { statusCode, body } = ctx.result;
  if (statusCode !== 200) {
    util.error(body);
  }
  const result = JSON.parse(body);
  return result.choices[0].message.content;
}
export {
  request,
  response
};
//# sourceMappingURL=data:application/json;base64,ewogICJ2ZXJzaW9uIjogMywKICAic291cmNlcyI6IFsiUXVlcnkuY29tcGxldGVDaGF0LnRzIl0sCiAgIm1hcHBpbmdzIjogIjtBQVFPLFNBQVMsUUFBUSxLQUFnRDtBQUNwRSxRQUFNLEVBQUUsT0FBTyxFQUFFLE9BQU8sRUFBRSxJQUFJLElBQUk7QUFDbEMsU0FBTztBQUFBLElBQ0gsUUFBUTtBQUFBLElBQ1IsY0FBYztBQUFBLElBQ2QsUUFBUTtBQUFBLE1BQ0osU0FBUztBQUFBLFFBQ0wsaUJBQWlCO0FBQUEsUUFDakIsZ0JBQWdCO0FBQUEsTUFDcEI7QUFBQSxNQUNBLE1BQU0sS0FBSyxVQUFVO0FBQUEsUUFDakIsT0FBTztBQUFBLFFBQ1AsVUFBVTtBQUFBLFVBQ04sRUFBRSxNQUFNLFFBQVEsU0FBUyxPQUFPO0FBQUEsUUFDcEM7QUFBQSxNQUNKLENBQUM7QUFBQSxJQUNMO0FBQUEsRUFDSjtBQUNKO0FBZ0JPLFNBQVMsU0FBUyxLQUE2RDtBQUVsRixRQUFNLEVBQUUsWUFBWSxLQUFLLElBQUksSUFBSTtBQUNqQyxNQUFJLGVBQWUsS0FBSztBQUNwQixTQUFLLE1BQU0sSUFBSTtBQUFBLEVBQ25CO0FBQ0EsUUFBTSxTQUFTLEtBQUssTUFBTSxJQUFJO0FBQzlCLFNBQU8sT0FBTyxRQUFRLENBQUMsRUFBRSxRQUFRO0FBQ3JDOyIsCiAgIm5hbWVzIjogW10KfQo=
