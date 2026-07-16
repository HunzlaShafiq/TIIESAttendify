import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tiies_attendance_app/Providers/botton_nav_provider.dart';
import 'package:tiies_attendance_app/Providers/checkIn_checkOut_provider.dart';
import 'package:tiies_attendance_app/Providers/google_Map_Provider.dart';
import 'package:tiies_attendance_app/Utils/Components/animatedCheckInOut.dart';
import 'package:tiies_attendance_app/Utils/Constant/AppColors.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {


  @override
  Widget build(BuildContext context) {
    return Scaffold(
          appBar: AppBar(
            title: const Text(
              "TIIES Attendance",
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: AppColors().mainColor,
            centerTitle: true,
          ),

          body:  Column(
            children: [
              const SizedBox(height: 12),

              Text(
                "Welcome To TIIES Attendify!",
                style: TextStyle(
                  fontSize: 22,
                  color: AppColors().mainColor,
                ),
              ),

              Consumer<CheckInCheckoutProvider>(
                  builder: (context,provider,_) {

                      return Column(
                        children: [
                          Text(
                            provider.getFormattedTime(context),
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors().mainColor,
                            ),
                          ),

                          Text(
                            provider.getFormattedDate(),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),


                          const SizedBox(height: 20),
                        ],
                      );

                  }
              ),

              Expanded(
                child: Consumer<GoogleMapProvider>(
                  builder: (context,provider,_) {
                   if(provider.mapLoading) {
                    return const Center(child: CircularProgressIndicator());
                   }
                   else{
                    return Column(
                       children: [

                         AnimatedCheckInOutButton(
                             onTap: () {
                               if(provider.attendanceAllowed){

                                 Provider.of<CheckInCheckoutProvider>(context,listen: false).checkIn(location: provider.currentPlaceName);
                                 Provider.of<BottomNavProvider>(context,listen: false).pageCheckIn();

                               }else{
                                 showOutOfRadiusSheet(context, provider);
                               }

                             },
                             isCheckIn: provider.attendanceAllowed,
                             buttonName: "CHECK-IN"
                         ),

                         const SizedBox(height: 15),
                         Text(
                           provider.attendanceAllowed
                               ? "Inside office radius"
                               : "Outside office radius",
                           style: TextStyle(
                             fontSize: 12,
                             color: provider.attendanceAllowed
                                 ? Colors.green
                                 : Colors.red,
                           ),
                         ),


                         Row(
                           mainAxisAlignment: MainAxisAlignment.center,
                           children: [
                             const Icon(
                               Icons.location_on_outlined,
                               color: Colors.grey,
                               size: 18,
                             ),
                             const SizedBox(width: 4),
                             Text(
                               provider.currentPlaceName,
                               style: const TextStyle(
                                 color: Colors.grey,
                                 fontSize: 12,
                               ),
                               maxLines: 1,
                               overflow: TextOverflow.ellipsis,
                             ),
                           ],
                         ),


                         const SizedBox(height: 10),

                         Flexible(
                           child: ClipRRect(
                             borderRadius: const BorderRadius.only(
                               topLeft: Radius.circular(30),
                               topRight: Radius.circular(30),
                             ),
                             child: GoogleMap(
                               mapType: MapType.hybrid,
                               markers: provider.userCurrentMarker,
                               myLocationButtonEnabled: true,
                               myLocationEnabled: true,
                               initialCameraPosition: provider.currentPosition,
                               onMapCreated: provider.onMapCreated,
                             ),
                           ),
                         ),
                       ],
                     );
                   }

                  }
                ),
              )


            ],
          ),
        );

  }
  void showOutOfRadiusSheet(
      BuildContext context,
      GoogleMapProvider provider,
      ) {showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              Container(
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              const SizedBox(height: 16),

              const Icon(
                Icons.location_off_rounded,
                size: 50,
                color: Colors.red,
              ),

              const SizedBox(height: 10),

              const Text(
                "Outside Office Radius",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                "You must be within office location to check-in.",
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 20),

              _infoRow(
                "Your Distance",
                provider.formattedDistance,
              ),
              _infoRow(
                "Allowed Radius",
                "${provider.allowedRadius.toStringAsFixed(0)} m",
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text("OK",style: TextStyle(color: Colors.white),),
              ),

              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

}

