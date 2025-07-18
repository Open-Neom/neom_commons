import 'package:get/get.dart';
import '../../utils/constants/app_assets.dart';
import '../../utils/constants/translations/common_translation_constants.dart';

class SliderModel{
  String imagePath;
  String title;
  String msg1;
  String msg2;

  SliderModel(this.imagePath, this.title, this.msg1, {this.msg2 = ""});


  static List<SliderModel> getOnboardingSlides(){
    List<SliderModel> slides = [];
    SliderModel s1 = SliderModel(AppAssets.logoAppWhite,
        CommonTranslationConstants.welcomeToApp.tr, CommonTranslationConstants.welcomeToAppMsg.tr);
    SliderModel s2 = SliderModel(AppAssets.intro02,
        CommonTranslationConstants.findItemmatesNearYourPlace.tr, CommonTranslationConstants.findItemmatesNearYourPlaceMsg.tr);
    SliderModel s3 = SliderModel(AppAssets.intro03,
        CommonTranslationConstants.letsGig.tr, CommonTranslationConstants.letsGigMsg.tr);
    slides.add(s1);
    slides.add(s2);
    slides.add(s3);
    return slides;
  }

  static List<SliderModel> getRequiredPermissionsSlides(){
    List<SliderModel> slides = [];
    SliderModel s1 = SliderModel(AppAssets.intro02,
        CommonTranslationConstants.locationRequiredTitle.tr, CommonTranslationConstants.locationRequiredMsg1.tr,
        msg2: CommonTranslationConstants.locationRequiredMsg2.tr);
    slides.add(s1);


    return slides;
  }

}
