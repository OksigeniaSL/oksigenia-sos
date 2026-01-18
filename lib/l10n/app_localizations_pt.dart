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
  String get statusLocationFixed => 'LOCALIZAÇÃO FIXADA';

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
  String get menuPrivacy => 'Privacidade e Legal';

  @override
  String get menuDonate => 'Donar / Donate';

  @override
  String get menuX => 'X (Twitter)';

  @override
  String get menuInsta => 'Instagram';

  @override
  String get motto => 'Respira > Inspira > Crece;';

  @override
  String panicMessage(Object link) {
    return '🆘 *ALERTA OKSIGENIA* 🆘\n\nPreciso de ajuda urgente.\n📍 Localização: $link\n\nRespira > Inspira > Crece;';
  }

  @override
  String get settingsTitle => 'Configuração SOS';

  @override
  String get settingsLabel => 'Telefone de Emergência';

  @override
  String get settingsHint => 'Ex: +351 912 345 678';

  @override
  String get settingsSave => 'GUARDAR';

  @override
  String get settingsSavedMsg => 'Contacto guardado corretamente';

  @override
  String get errorNoContact => '⚠️ Configure um contacto primeiro!';

  @override
  String get autoModeLabel => 'Deteção de Quedas';

  @override
  String get autoModeDescription => 'Monitoriza impactos severos.';

  @override
  String get inactivityModeLabel => 'Monitor de Inatividade';

  @override
  String get inactivityModeDescription =>
      'Alerta si não for detectado movimento.';

  @override
  String get alertFallDetected => 'IMPACTO DETETADO!';

  @override
  String get alertFallBody => 'Queda severa detetada. Estás bem?';

  @override
  String get alertInactivityDetected => 'INATIVIDADE DETETADA!';

  @override
  String get alertInactivityBody => 'Sem movimento detetado. Estás bem?';

  @override
  String get btnImOkay => 'ESTOU BEM';

  @override
  String get disclaimerTitle => '⚠️ AVISO LEGAL E PRIVACIDAD';

  @override
  String get disclaimerText => 'Oksigenia SOS é uma ferramenta de apoio.';

  @override
  String get btnAccept => 'ACEITO O RISCO';

  @override
  String get btnDecline => 'SAIR';

  @override
  String get privacyTitle => 'Termos e Privacidade';

  @override
  String get privacyPolicyContent => 'POLÍTICA DE PRIVACIDAD Y TÉRMINOS';

  @override
  String get advSettingsTitle => 'Funções Avançadas';

  @override
  String get advSettingsSubtitle => 'Multi-contacto, Rastreio GPS...';

  @override
  String get dialogCommunityTitle => '💎 Comunidade Oksigenia';

  @override
  String get dialogCommunityBody => 'Versão COMMUNITY (Grátis).';

  @override
  String get dialogStoreTitle => '🔒 Oksigenia Pro';

  @override
  String get dialogStoreBody => 'Subscreva o PRO.';

  @override
  String get btnDonate => 'Ofereça-me um café ☕';

  @override
  String get btnSubscribe => 'Subscrever';

  @override
  String get btnClose => 'Fechar';

  @override
  String get permSmsTitle => 'PERIGO! Permissão SMS bloqueada';

  @override
  String get permSmsBody => 'A aplicação NÃO pode enviar alertas.';

  @override
  String get permSmsButton => 'Ativar SMS';

  @override
  String get restrictedSettingsTitle => 'Definições Restritas';

  @override
  String get restrictedSettingsBody => 'O Android restringiu esta permissão.';

  @override
  String get btnGoToSettings => 'DEFINIÇÕES';

  @override
  String get contactsTitle => 'Contactos de Emergência';

  @override
  String get contactsSubtitle => 'O primeiro recebe o rastreio GPS.';

  @override
  String get contactsAddHint => 'Novo número';

  @override
  String get contactsEmpty => '⚠️ Sem contactos.';

  @override
  String get messageTitle => 'Mensagem Personalizada';

  @override
  String get messageSubtitle => 'Enviada ANTES das coordenadas.';

  @override
  String get messageHint => 'Ex : Diabético. Rota Norte...';

  @override
  String get trackingTitle => 'Rastreio GPS';

  @override
  String get trackingSubtitle => 'Envia posição a intervalos.';

  @override
  String get trackOff => '❌ Desactivado';

  @override
  String get track30 => '⏱️ A cada 30 min';

  @override
  String get track60 => '⏱️ A cada 1 hora';

  @override
  String get track120 => '⏱️ A cada 2 horas';

  @override
  String get contactMain => 'Principal';

  @override
  String get inactivityTimeTitle => 'Tempo para Alerta';

  @override
  String get inactivityTimeSubtitle => 'Quanto tempo sem movimento?';

  @override
  String get ina30s => '🧪 30 seg';

  @override
  String get ina1h => '⏱️ 1 hora';

  @override
  String get ina2h => '⏱️ 2 horas';

  @override
  String get testModeWarning => '⚠️ MODO TEST ATIVO: 30s.';

  @override
  String get toastHoldToSOS => 'Segure para SOS';

  @override
  String get donateDialogTitle => '💎 Apoie o Projeto';

  @override
  String get donateDialogBody => 'Pague-nos um café.';

  @override
  String get donateBtn => 'Doar via PayPal';

  @override
  String get donateClose => 'FECHAR';
}
