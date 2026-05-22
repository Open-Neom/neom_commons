enum AppDrawerMenu {
  profile("profile"),
  frequencies("frequencies"),
  presets("presets"),
  instruments("instruments"),
  genres("genres"),
  digitalLibrary("digitalLibrary"),
  collectives("collectives"),
  events("events"),
  inbox("inbox"),
  calendar("calendar"),
  services("services"),
  requests("requests"),
  booking("booking"),
  directory("directory"),
  ///DEPRECATED wallet("wallet"),
  settings("settings"),
  appItemQuotation("appItemQuotation"),
  crowdfunding("crowdfunding"),
  logout("logout"),
  releaseUpload("releaseUpload"),
  inspiration("inspiration"),
  ///DEPRECATED nupale("nupale"),
  ///DEPRECATED casete("casete"),
  games("games"),
  learning("learning"),
  vst("vst"),
  daw("daw"),
  erp("erp"),
  dashboard("dashboard");


  final String value;
  const AppDrawerMenu(this.value);

}
