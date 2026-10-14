import { useState, type FormEvent } from 'react';
import { ArrowLeft, ArrowRight, BookOpen, CheckCircle2, LockKeyhole, Mail, Smartphone } from 'lucide-react';
import { LanguageSwitcher } from '@/components/language-switcher';
import { useLanguage } from '@/hooks/use-language';

export type AuthScreenProps = {
  onRequestCode: (identifier: string) => void | Promise<void>;
  onVerifyCode: (identifier: string, code: string) => void | Promise<void>;
  loading?: boolean;
  error?: string | null;
  setupMissing?: boolean;
};

export function AuthScreen({
  onRequestCode,
  onVerifyCode,
  loading = false,
  error,
  setupMissing = false,
}: AuthScreenProps) {
  const { t } = useLanguage();
  const [identifier, setIdentifier] = useState('');
  const [code, setCode] = useState('');
  const [step, setStep] = useState<'identifier' | 'code'>('identifier');
  const [localError, setLocalError] = useState('');
  const [sent, setSent] = useState(false);
  const visibleError = error || localError;
  const isValidIdentifier = identifier.trim().length >= 5;

  async function requestCode(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setLocalError('');
    if (!isValidIdentifier) {
      setLocalError(t('invalidIdentifier'));
      return;
    }
    try {
      await onRequestCode(identifier.trim());
      setStep('code');
      setSent(true);
    } catch {
      setLocalError(t('sendFailed'));
    }
  }

  async function verifyCode(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setLocalError('');
    if (code.trim().length < 4) {
      setLocalError(t('codeRequired'));
      return;
    }
    try {
      await onVerifyCode(identifier.trim(), code.trim());
    } catch {
      setLocalError(t('verifyFailed'));
    }
  }

  return (
    <main className="vs-shell">
      <header className="vs-topbar">
        <div className="vs-brand" aria-label="VidyaSetu">
          <span className="vs-brand-mark"><BookOpen size={22} strokeWidth={2.2} /></span>
          <span>
            <span className="vs-brand-name">VidyaSetu</span>
            <span className="vs-brand-caption" style={{ display: 'block' }}>{t('brandCaption')}</span>
          </span>
        </div>
        <div className="vs-top-actions">
          <LanguageSwitcher />
          <span className="vs-pill"><LockKeyhole size={14} /> {t('secureSignIn')}</span>
        </div>
      </header>

      <div className="vs-auth-layout">
        <section className="vs-auth-copy">
          <span className="vs-eyebrow">{t('authEyebrow')}</span>
          <h1 className="vs-heading">{t('authHeadline')}</h1>
          <p className="vs-lede">
            {t('authIntro')}
          </p>
          <div className="vs-bridge-art" aria-hidden="true">
            <span className="vs-sun" />
            <span className="vs-horizon" />
          </div>
        </section>

        <section className="vs-form-card" aria-labelledby="auth-title">
          {step === 'identifier' ? (
            <>
              <h2 id="auth-title">{t('authTitle')}</h2>
              <p>{t('authDescription')}</p>
              <form onSubmit={requestCode} noValidate>
                <label className="vs-form-label" htmlFor="identifier">{t('identifierLabel')}</label>
                <input
                  className="vs-input"
                  id="identifier"
                  name="identifier"
                  type="text"
                  data-testid="input-identifier"
                  inputMode={
                    identifier.trim() && !identifier.includes("@")
                      ? "tel"
                      : "email"
                  }
                  autoComplete="username"
                  placeholder={t('identifierPlaceholder')}
                  value={identifier}
                  onChange={(event) => setIdentifier(event.target.value)}
                  disabled={loading || setupMissing}
                  required
                />
                {visibleError && <p className="vs-error" role="alert" data-testid="status-auth-error">{visibleError}</p>}
                <button className="vs-primary-button" type="submit" disabled={loading || setupMissing} data-testid="button-request-code">
                  {loading ? t('sendingCode') : t('sendCode')} <ArrowRight size={18} />
                </button>
              </form>
              {setupMissing ? (
                <div className="vs-info-box" role="status" data-testid="status-setup-missing">
                  {t('setupMissing')}
                </div>
              ) : (
                <p className="vs-helper">{t('passwordless')}</p>
              )}
            </>
          ) : (
            <>
              <button
                type="button"
                className="vs-text-button"
                onClick={() => { setStep('identifier'); setCode(''); setLocalError(''); }}
                disabled={loading}
                aria-label={t('changeDetails')}
                data-testid="button-change-identifier"
              >
                <ArrowLeft size={15} style={{ verticalAlign: 'middle', marginRight: 5 }} /> {t('changeDetails')}
              </button>
              <h2 id="auth-title" style={{ marginTop: 17 }}>{t('checkMessages')}</h2>
              <p>{t('enterCodeDescription')} <strong>{identifier}</strong>. {identifier.includes('@') && t('orUseEmailLink')}</p>
              {sent && <div className="vs-info-box" role="status" data-testid="status-code-sent"><CheckCircle2 size={16} style={{ verticalAlign: 'middle', marginRight: 7 }} /> {t('codeOnItsWay')}</div>}
              <form onSubmit={verifyCode} noValidate>
                <label className="vs-form-label" htmlFor="otp-code">{t('oneTimeCode')}</label>
                <input
                  className="vs-input vs-code-input"
                  id="otp-code"
                  name="code"
                  type="text"
                  data-testid="input-otp-code"
                  inputMode="numeric"
                  autoComplete="one-time-code"
                  placeholder={t('enterCode')}
                  value={code}
                  onChange={(event) => setCode(event.target.value.replace(/\s/g, '').slice(0, 8))}
                  disabled={loading}
                  required
                />
                {visibleError && <p className="vs-error" role="alert" data-testid="status-auth-error">{visibleError}</p>}
                <button className="vs-primary-button" type="submit" disabled={loading || code.trim().length < 4} data-testid="button-verify-code">
                  {loading ? t('checkingCode') : t('verifyContinue')} <ArrowRight size={18} />
                </button>
              </form>
              <p className="vs-helper">
                <button
                  type="button"
                  className="vs-text-button"
                  data-testid="button-resend-code"
                  onClick={async () => {
                    setLocalError('');
                    try {
                      await onRequestCode(identifier.trim());
                      setSent(true);
                    } catch {
                      setLocalError(t('resendFailed'));
                    }
                  }}
                  disabled={loading}
                >
                  {t('resendCode')}
                </button>
              </p>
            </>
          )}
          <div className="vs-helper" style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            {identifier.includes('@') ? <Mail size={15} /> : <Smartphone size={15} />}
            {t('signInOnly')}
          </div>
        </section>
      </div>
      <footer className="vs-footer">{t('footer')}</footer>
    </main>
  );
}
