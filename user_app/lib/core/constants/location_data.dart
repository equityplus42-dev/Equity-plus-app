class LocationData {
  static const List<String> states = [
    'West Bengal',
    'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chhattisgarh',
    'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jharkhand', 'Karnataka',
    'Kerala', 'Madhya Pradesh', 'Maharashtra', 'Manipur', 'Meghalaya', 'Mizoram',
    'Nagaland', 'Odisha', 'Punjab', 'Rajasthan', 'Sikkim', 'Tamil Nadu',
    'Telangana', 'Tripura', 'Uttar Pradesh', 'Uttarakhand',
    'Andaman and Nicobar Islands', 'Chandigarh', 'Dadra and Nagar Haveli', 
    'Daman and Diu', 'Delhi', 'Lakshadweep', 'Puducherry'
  ];

  static const Map<String, List<String>> stateDistricts = {
    'West Bengal': [
      'Alipurduar', 'Bankura', 'Birbhum', 'Cooch Behar', 'Dakshin Dinajpur',
      'Darjeeling', 'Hooghly', 'Howrah', 'Jalpaiguri', 'Jhargram', 'Kalimpong',
      'Kolkata', 'Malda', 'Murshidabad', 'Nadia', 'North 24 Parganas',
      'Paschim Bardhaman', 'Paschim Medinipur', 'Purba Bardhaman',
      'Purba Medinipur', 'Purulia', 'South 24 Parganas', 'Uttar Dinajpur'
    ],
    'Bihar': [
      'Patna', 'Gaya', 'Bhagalpur', 'Muzaffarpur', 'Purnia', 'Darbhanga',
      'Aurangabad', 'Begusarai', 'Katihar', 'Chapra'
    ],
    'Odisha': [
      'Bhubaneswar', 'Cuttack', 'Rourkela', 'Puri', 'Sambalpur', 'Balasore'
    ],
    'Jharkhand': [
      'Ranchi', 'Jamshedpur', 'Dhanbad', 'Bokaro', 'Deoghar', 'Hazaribagh'
    ],
    'Delhi': [
      'Central Delhi', 'East Delhi', 'New Delhi', 'North Delhi', 'South Delhi', 'West Delhi'
    ],
    'Maharashtra': [
      'Mumbai', 'Pune', 'Nagpur', 'Thane', 'Nashik', 'Aurangabad'
    ],
    'Karnataka': [
      'Bengaluru', 'Mysuru', 'Mangaluru', 'Hubli', 'Belagavi'
    ]
  };

  static List<String> getDistrictsForState(String? state) {
    if (state == null || state.isEmpty) return [];
    return stateDistricts[state] ?? ['Other / Type Manually'];
  }
}
