type MessagePayload = Record<string, unknown>;

const isFiveMEnvironment = () =>
	typeof window !== 'undefined' && typeof window.GetParentResourceName === 'function';

export const isFiveM = () => isFiveMEnvironment();

export const postNui = async <TResponse = unknown>(
	eventName: string,
	data: MessagePayload = {}
): Promise<TResponse | null> => {
	if (!isFiveMEnvironment()) return null;
	const resourceName = window.GetParentResourceName?.();
	if (!resourceName) return null;

	const response = await fetch(`https://${resourceName}/${eventName}`, {
		method: 'POST',
		headers: {
			'Content-Type': 'application/json; charset=UTF-8'
		},
		body: JSON.stringify(data)
	});

	try {
		return (await response.json()) as TResponse;
	} catch {
		return null;
	}
};

export const onNuiMessage = (handler: (payload: MessagePayload) => void) => {
	const listener = (event: MessageEvent<MessagePayload>) => {
		if (!event.data || typeof event.data !== 'object') return;
		handler(event.data);
	};

	window.addEventListener('message', listener);
	return () => window.removeEventListener('message', listener);
};
