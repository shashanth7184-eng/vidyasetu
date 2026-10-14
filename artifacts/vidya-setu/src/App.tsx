import { useState, type ReactNode } from "react";
import {
  BrowserRouter,
  Navigate,
  Route,
  Routes,
  useParams,
} from "react-router-dom";
import { ErrorBoundary } from "@/components/error-boundary";
import { AuthScreen } from "@/components/auth-screen";
import {
  PendingAccessScreen,
  RoleDashboard,
} from "@/components/role-dashboard";
import { AuthProvider, useAuth } from "@/hooks/use-auth";
import { LanguageProvider, useLanguage } from "@/hooks/use-language";
import { Toaster } from "@/components/ui/toaster";
import { TooltipProvider } from "@/components/ui/tooltip";
import NotFound from "@/pages/not-found";
import { roleDashboardPath } from "@/lib/roles";
import "./index.css";

function StatusScreen({ children }: { children: ReactNode }) {
  return (
    <main className="vs-shell">
      <div className="vs-status-card" role="status">
        {children}
      </div>
    </main>
  );
}

function LoadingScreen() {
  const { t } = useLanguage();
  return <StatusScreen>{t("statusLoading")}</StatusScreen>;
}

function LoginRoute() {
  const { status, profile, error, requestCode, verifyCode } = useAuth();
  const [submitting, setSubmitting] = useState(false);
  const [actionError, setActionError] = useState<string | null>(null);

  if (status === "loading") return <LoadingScreen />;
  if (status === "signed-in" && profile) {
    return <Navigate to={roleDashboardPath(profile.role)} replace />;
  }
  if (status === "profile-missing") {
    return <Navigate to="/pending-access" replace />;
  }

  async function runAuthAction(action: () => Promise<void>) {
    setSubmitting(true);
    setActionError(null);
    try {
      await action();
    } catch (actionFailure) {
      setActionError(
        actionFailure instanceof Error
          ? actionFailure.message
          : "Sign-in could not be completed. Please try again.",
      );
      throw actionFailure;
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <AuthScreen
      onRequestCode={(identifier) =>
        runAuthAction(() => requestCode(identifier))
      }
      onVerifyCode={(identifier, code) =>
        runAuthAction(() => verifyCode(identifier, code))
      }
      loading={submitting}
      error={actionError ?? (status === "error" ? error : null)}
      setupMissing={status === "unconfigured"}
    />
  );
}

function PendingAccessRoute() {
  const { t } = useLanguage();
  const { status, profile, signOut } = useAuth();
  if (status === "loading") return <LoadingScreen />;
  if (status === "signed-out" || status === "unconfigured") {
    return <Navigate to="/login" replace />;
  }
  if (status === "signed-in" && profile) {
    return <Navigate to={roleDashboardPath(profile.role)} replace />;
  }
  if (status === "profile-missing") {
    return <PendingAccessScreen onSignOut={signOut} />;
  }
  return (
    <StatusScreen>
      {t("profileError")}
    </StatusScreen>
  );
}

function RoleDashboardRoute() {
  const { t } = useLanguage();
  const { role } = useParams<{ role: string }>();
  const { status, profile, signOut } = useAuth();

  if (status === "loading") return <LoadingScreen />;
  if (status === "signed-out" || status === "unconfigured") {
    return <Navigate to="/login" replace />;
  }
  if (status === "profile-missing") {
    return <Navigate to="/pending-access" replace />;
  }
  if (status !== "signed-in" || !profile) {
    return (
      <StatusScreen>
        {t("unknownProfileError")}
      </StatusScreen>
    );
  }

  if (role !== profile.role) {
    return <Navigate to={roleDashboardPath(profile.role)} replace />;
  }

  return <RoleDashboard profile={profile} onSignOut={signOut} />;
}

function HomeRoute() {
  const { status, profile } = useAuth();
  if (status === "loading") return <LoadingScreen />;
  if (status === "signed-in" && profile) {
    return <Navigate to={roleDashboardPath(profile.role)} replace />;
  }
  if (status === "profile-missing") {
    return <Navigate to="/pending-access" replace />;
  }
  return <Navigate to="/login" replace />;
}

function AppRoutes() {
  return (
    <Routes>
      <Route path="/" element={<HomeRoute />} />
      <Route path="/login" element={<LoginRoute />} />
      <Route path="/pending-access" element={<PendingAccessRoute />} />
      <Route path="/dashboard/:role" element={<RoleDashboardRoute />} />
      <Route path="*" element={<NotFound />} />
    </Routes>
  );
}

function App() {
  const baseName =
    import.meta.env.BASE_URL === "/"
      ? undefined
      : import.meta.env.BASE_URL.replace(/\/$/, "");

  return (
    <ErrorBoundary>
      <LanguageProvider>
        <AuthProvider>
          <TooltipProvider>
            <BrowserRouter basename={baseName}>
              <AppRoutes />
            </BrowserRouter>
            <Toaster />
          </TooltipProvider>
        </AuthProvider>
      </LanguageProvider>
    </ErrorBoundary>
  );
}

export default App;
