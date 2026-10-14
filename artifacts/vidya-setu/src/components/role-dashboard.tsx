import { useState } from 'react';
import { BookOpen, HeartHandshake, MapPin, School, ShieldCheck, Signpost, LogOut } from 'lucide-react';
import { LanguageSwitcher } from '@/components/language-switcher';
import { useLanguage } from '@/hooks/use-language';
import type { TranslationKey } from '@/lib/i18n';
import type { Profile } from '@/types/auth';

export type { Profile } from '@/types/auth';

export type RoleDashboardProps = {
  profile: Profile;
  onSignOut: () => void | Promise<void>;
};

type RoleContent = {
  title: TranslationKey;
  focus: TranslationKey;
  nextTitle: TranslationKey;
  nextText: TranslationKey;
  label: TranslationKey;
};

const roleContent: Record<Profile['role'], RoleContent> = {
  admin: {
    title: 'roleAdminTitle',
    focus: 'roleAdminFocus',
    nextTitle: 'roleAdminNextTitle',
    nextText: 'roleAdminNextText',
    label: 'roleAdminLabel',
  },
  teacher: {
    title: 'roleTeacherTitle',
    focus: 'roleTeacherFocus',
    nextTitle: 'roleTeacherNextTitle',
    nextText: 'roleTeacherNextText',
    label: 'roleTeacherLabel',
  },
  volunteer: {
    title: 'roleVolunteerTitle',
    focus: 'roleVolunteerFocus',
    nextTitle: 'roleVolunteerNextTitle',
    nextText: 'roleVolunteerNextText',
    label: 'roleVolunteerLabel',
  },
  parent: {
    title: 'roleParentTitle',
    focus: 'roleParentFocus',
    nextTitle: 'roleParentNextTitle',
    nextText: 'roleParentNextText',
    label: 'roleParentLabel',
  },
};

export function RoleDashboard({ profile, onSignOut }: RoleDashboardProps) {
  const { t } = useLanguage();
  const [signOutError, setSignOutError] = useState('');
  const content = roleContent[profile.role];
  const displayName = profile.full_name.trim() || t('welcomeFallback');

  async function handleSignOut() {
    setSignOutError('');
    try {
      await onSignOut();
    } catch {
      setSignOutError(t('signOutFailed'));
    }
  }

  return (
    <main className="vs-shell">
      <header className="vs-topbar">
        <div className="vs-brand">
          <span className="vs-brand-mark"><BookOpen size={22} strokeWidth={2.2} /></span>
          <span>
            <span className="vs-brand-name">VidyaSetu</span>
            <span className="vs-brand-caption" style={{ display: 'block' }}>{t('brandCaption')}</span>
          </span>
        </div>
        <div className="vs-top-actions">
          <LanguageSwitcher />
          <span className="vs-pill"><ShieldCheck size={14} /> {t(content.label)}</span>
        </div>
      </header>

      <div className="vs-dashboard-wrap">
        <div className="vs-dashboard-top">
          <div>
            <div className="vs-eyebrow" data-testid="text-role-home">{t('roleHome')}</div>
          </div>
          <button className="vs-signout" type="button" onClick={() => void handleSignOut()} data-testid="button-sign-out">
            <LogOut size={16} /> {t('signOut')}
          </button>
        </div>
        {signOutError && <p className="vs-error" role="alert">{signOutError}</p>}

        <section className="vs-welcome" aria-labelledby="welcome-title">
          <span className="vs-eyebrow">{t(content.focus)}</span>
          <h1 id="welcome-title" data-testid="text-profile-name">{t('roleGreeting')} {displayName}.</h1>
          <p>{t(content.title)}</p>
          <div className="vs-profile-strip">
            <span className="vs-profile-item"><HeartHandshake size={15} /> {t(content.label)}</span>
            {profile.school_id && <span className="vs-profile-item"><School size={15} /> {t('schoolLinked')}</span>}
            {profile.village && <span className="vs-profile-item"><MapPin size={15} /> {t('villageLabel')}: {profile.village}</span>}
          </div>
        </section>

        <section className="vs-dash-section" aria-labelledby="next-title">
          <h2 id="next-title">{t('welcomeHeading')}</h2>
          <div className="vs-next-card">
            <span className="vs-next-icon"><Signpost size={21} /></span>
            <div>
              <h3>{t(content.nextTitle)}</h3>
              <p>{t(content.nextText)}</p>
            </div>
          </div>
        </section>
      </div>
      <footer className="vs-footer">{t('footer')}</footer>
    </main>
  );
}

export type PendingAccessScreenProps = {
  onSignOut: () => void | Promise<void>;
};

export function PendingAccessScreen({ onSignOut }: PendingAccessScreenProps) {
  const { t } = useLanguage();
  const [signOutError, setSignOutError] = useState('');

  async function handleSignOut() {
    setSignOutError('');
    try {
      await onSignOut();
    } catch {
      setSignOutError(t('signOutFailed'));
    }
  }

  return (
    <main className="vs-shell">
      <header className="vs-topbar">
        <div className="vs-brand">
          <span className="vs-brand-mark"><BookOpen size={22} strokeWidth={2.2} /></span>
          <span>
            <span className="vs-brand-name">VidyaSetu</span>
            <span className="vs-brand-caption" style={{ display: 'block' }}>{t('brandCaption')}</span>
          </span>
        </div>
        <div className="vs-top-actions">
          <LanguageSwitcher />
          <span className="vs-pill"><ShieldCheck size={14} /> {t('pendingPill')}</span>
        </div>
      </header>
      <section className="vs-pending" aria-labelledby="pending-title">
        <span className="vs-pending-mark"><School size={28} /></span>
        <span className="vs-eyebrow">{t('pendingEyebrow')}</span>
        <h1 id="pending-title">{t('pendingTitle')}</h1>
        <p>
          {t('pendingMessage')}
        </p>
        <button className="vs-signout" type="button" onClick={() => void handleSignOut()} data-testid="button-sign-out">
          <LogOut size={16} /> {t('signOut')}
        </button>
        {signOutError && <p className="vs-error" role="alert">{signOutError}</p>}
      </section>
      <footer className="vs-footer">{t('footer')}</footer>
    </main>
  );
}
