import { z } from 'zod';

export const PlanSchema = z.object({
    id: z.string(),
    name: z.string(),
    price: z.number(),
});

export type Plan = z.infer<typeof PlanSchema>;
