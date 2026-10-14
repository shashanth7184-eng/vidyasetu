import type { AppRole } from "@/types/auth";

export const roleDashboardPath = (role: AppRole) => `/dashboard/${role}`;
