// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Oksigenia SOS';

  @override
  String get sosButton => 'SOS';

  @override
  String get statusReady => 'Sistema Oksigenia Pronto.';

  @override
  String get statusConnecting => 'Conectando satélites...';

  @override
  String get statusLocationFixed => 'LOCALIZAÇÃO FIXA';

  @override
  String get statusSent => 'Alerta enviado com sucesso.';

  @override
  String statusError(Object error) {
    return 'ERRO: $error';
  }

  @override
  String get menuWeb => 'Site Oficial';

  @override
  String get menuSupport => 'Suporte Técnico';

  @override
  String get menuLanguages => 'Idioma';

  @override
  String get menuSettings => 'Configurações';

  @override
  String get motto => 'Respira > Inspira > Crece;';

  @override
  String panicMessage(Object link) {
    return '🆘 *ALERTA OKSIGENIA* 🆘\n\nPreciso de ajuda urgente.\n📍 Localização: $link\n\nRespira > Inspira > Crece;';
  }

  @override
  String get settingsTitle => 'Configuração SOS';

  @override
  String get settingsLabel => 'Número de Emergência';

  @override
  String get settingsHint => 'Ex: +351 900 123 456';

  @override
  String get settingsSave => 'SALVAR';

  @override
  String get settingsSavedMsg => 'Contato salvo';

  @override
  String get errorNoContact => '⚠️ Configure um contato primeiro!';

  @override
  String get autoModeLabel => 'Detecção de Queda';

  @override
  String get autoModeDescription => 'Monitora impactos severos.';

  @override
  String get inactivityModeLabel => 'Monitor de Inatividade';

  @override
  String get inactivityModeDescription => 'Alerta se não houver movimento.';

  @override
  String get alertFallDetected => 'IMPACTO DETECTADO!';

  @override
  String get alertFallBody => 'Queda severa detectada. Você está bem?';

  @override
  String get alertInactivityDetected => 'INATIVIDADE DETECTADA!';

  @override
  String get alertInactivityBody => 'Sem movimento. Você está bem?';

  @override
  String get btnImOkay => 'ESTOU BEM';

  @override
  String get disclaimerTitle => '⚠️ AVISO LEGAL E PRIVACIDADE';

  @override
  String get disclaimerText =>
      'Oksigenia SOS é uma ferramenta de apoio. Sua operação depende de bateria, GPS e rede móvel.\n\nVocê aceita usar o software \'como está\' e assume os riscos.';

  @override
  String get btnAccept => 'ACEITO O RISCO';

  @override
  String get btnDecline => 'SAIR';

  @override
  String get menuPrivacy => 'Privacidade e Legal';

  @override
  String get privacyTitle => 'Termos e Privacidade';

  @override
  String get privacyPolicyContent =>
      'POLÍTICA DE PRIVACIDADE\n\n1. SEM COLETA DE DADOS\nOperação local.\n\n2. PERMISSÕES\n- GPS: Para alerta.\n- SMS: Para socorro.\n\n3. RESPONSABILIDADE\nSoftware fornecido sem garantia.';

  @override
  String get advSettingsTitle => 'Funções Avançadas';

  @override
  String get advSettingsSubtitle => 'Multi-contato, Rastreamento...';

  @override
  String get dialogCommunityTitle => '💎 Comunidade Oksigenia';

  @override
  String get dialogCommunityBody =>
      'Versão COMMUNITY (Grátis).\n\nCódigo aberto.\n\nConsidere doar se for útil.';

  @override
  String get dialogStoreTitle => '🔒 Oksigenia Pro';

  @override
  String get dialogStoreBody => 'Assine o PRO para rastreamento em tempo real.';

  @override
  String get btnDonate => 'Pague-me um café ☕';

  @override
  String get btnSubscribe => 'Assinar';

  @override
  String get btnClose => 'Fechar';
}
