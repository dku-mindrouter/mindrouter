const snippets: Record<string, { title: string; body: string; riskFlag: boolean }> = {
  '공허함:밤': {
    title: '오늘의 심리 스니펫',
    body: '공허함은 약함이 아니라 에너지가 비어 있다는 신호일 수 있어요.',
    riskFlag: false,
  },
  '무기력:아침': {
    title: '오늘의 심리 스니펫',
    body: '무기력한 아침에는 시작 기준을 평소보다 더 작게 잡아도 괜찮아요.',
    riskFlag: false,
  },
};

Deno.serve(async (request) => {
  const body = await request.json();
  const key = `${body.primaryTagName}:${body.timeBucket}`;
  const result = snippets[key] ?? {
    title: '오늘의 심리 스니펫',
    body: '오늘의 감정은 해결해야 할 문제가 아니라 먼저 알아차릴 신호일 수 있어요.',
    riskFlag: false,
  };

  return Response.json(result);
});
