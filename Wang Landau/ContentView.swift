//
//  ContentView.swift
//  Final Project Part 3
//
//  Created by Tim Stack on 5/18/23.
//

import SwiftUI
import Foundation
import Charts

struct ContentView: View {
    
    @State var wangLandauOutputText = ""
    @State var histogram :[Double] = []
    @State var lnDos :[Double] = []
    
    @State var numberOfSpins :Int = 8 * 8
    @State var spinArray :[Int]  = []       //array of spins of the particles
    @State var energyPriorToSpinFlip :Int = 0
    @State var energyAfterSpinFlip :Int = 0     //The energy of the system before the next spin is flipped and after
    @State var indexSpinToFlip :Int = 0    //Index of the Spin To Flip
    @State var rowSpinToFlip: Int = 0
    @State var columnSpinToFlip :Int = 0   //Row and Column Index Of Spin To Flip
    @State var lnDOS :[Double] = []    //The natural log of the Density of States
    @State var entropy :[Double]  = []  //Entropy, here it is just the logarithm of the kbT*ln(g(E)) or kbT*lnDOS
    @State var initalEnergy :Double = 0
    @State var previousEnergy :Double = 0  //Initial Energy of the system, energy of the last state
    @State var histogramOfEnergyStates :[Double] = []   //The histogram represents the number of times each energy state is visited
    @State var histogramToPlot : [Double] = []
    @State var histogramData = [DensityOfStatesHistogram]()
    @State var maximumValueOfHistogram :Double = 0
    @State var minimumValueOfHistogram :Double = 0  //The maximum and minimum values of the histograms are used to determine the flatness of the histogram function
    @State var heightOfHistogram :Double = 0.0
    @State var sumOfHistogram :Double = 0.0  //height of the histogram and its sum of max min value
    @State var f :Double = 2.71828
    //var f = Double.pi
    @State var tolerance :Double = 1e-5  //The logarithm of the initial guess of the correction factor f for Density Of States, f is initially set to e, tolerance for the correction
    @State var kb :Double = 8.617343e-5   //Boltzmann Constant in eV/K
    @State var temp :Double = 0.0
    @State var lambda:Double = 0.0
    @State var internalEnergy:Double = 0.0  //temperature; common factor lambda in internal energy calculation; internal energy
    @State var numerator:Double = 0.0
    @State var denominator:Double = 0.0
    @State var exponent:Double = 0.0  //numeator and denominator sums in the statistical calculations; exponent in the same calculations
    @State var  numeratorM:Double = 0.0
    @State var M:Double = 0.0   //numerator sum for calculating the magnetization; magnetization
    @State var numeratorU2:Double = 0.0
    @State var U2:Double = 0.0
    @State var Cv:Double = 0.0  //numerator sum for fluctuations in internal enrgy U2; luctuations in internal enrgy U2; specific heat
    @State var spinArrayRows:Int = 0
    @State var spinArrayColumns:Int = 0  //number of rows and columns in spinArray
    @State var dimension :Int = 8   //size of rows and columns
    @State var probabilityCondition: Double = 0.0 //probability condition to accept high probability state
    @State var newEnergy :Int = 0    //energy after the probability check
    @State var i:Int = 0
    @State var j:Int = 0
    @State var iplus1:Int = 0
    @State var iminus1:Int = 0
    @State var jplus1:Int = 0
    @State var jminus1:Int = 0
    @State var iterationCounter = 0
    @State var hasZeros = false
    @StateObject var myEnergy = Energy()
    
    var body: some View {
        VStack {
            HStack {
                VStack {
                    Text("Density of States")
                    Chart {
                        ForEach(histogramData, id: \.energies) { item in
                            BarMark(
                                x: .value("Energy", item.energies),
                                y: .value("Density of States", item.densityOfStates)
                            )
                        }
                    }
                    .chartXAxisLabel(position: .bottom, alignment: .center) {
                        Text("Energy")
                    }
//                    .chartYAxisLabel(position: .bottom, alignment: .center) {
//                        Text("Density of States")
//                    }
                    .padding()
                }
                VStack {
                    Text("Histogram")
                    Chart {
                        ForEach(histogramData, id: \.energies) { item in
                            BarMark(
                                x: .value("Energy", item.energies),
                                y: .value("Histogram", item.histogram)
                            )
                        }
                    }
                    .chartXAxisLabel(position: .bottom, alignment: .center) {
                        Text("Energy")
                    }
//                    .chartYAxisLabel(position: .bottom, alignment: .center) {
//                        Text("Histogram")
//                    }
                    .padding()
                }
            }
            
            HStack {
//                Text("N:")
//                TextField("N:", text: $Num)
//                    .padding()
//
//                Text("kT:")
//                TextField("kT:", text: $kT)
//                    .padding()
                
                Button("Start", action: calculateWangLandau)
                    .padding()
            }
        }
    }
    
    func calculateWangLandau()  {
        
        initializeMatrices()
        coldStart()
        
        /*********** Begin Spin Flipping To Determine lnDOS *************************/
        
        while( f >= (1+tolerance) )                                            //The process takes place until the correction factor is within the tolerance
        {
            
            iterationCounter += 1                                        //iteration number updated
            
            /********** Choose a Spin To Flip  *******************/
            
            indexSpinToFlip = Int.random(in: 0..<numberOfSpins)     //Gets a random number between 0 and the numberOfStates-1. The probability of choosing any particle is equal.
            
            /********** Calculate The Row and Column Of The Spin To Be Flipped, Need To Check Neigbors As We Assume Born-Von Karmen Boundary Conditions **********/
            
            columnSpinToFlip = indexSpinToFlip%spinArrayColumns
            rowSpinToFlip = indexSpinToFlip/spinArrayColumns
            
            //print("%d, %d", rowSpinToFlip, columnSpinToFlip)
            
            /******************************************************************************************************************/
            /********** In a 2D system, the change in energy due to flipping a spin is: ***************************************/
            /**********                                                                 ***************************************/
            /**********        deltaE = 2*(si,j)*(si+i,j + si-1,j + si,j-1 + si,j+1)       ***************************************/
            /******************************************************************************************************************/
            
            /********* We must check the boundary conditions though ***********************************************************/
            
            if(rowSpinToFlip == 0)
            {
                iminus1=spinArrayRows-1
                iplus1=rowSpinToFlip+1
            }
            else if(rowSpinToFlip == (spinArrayRows-1))
            {
                iplus1=0
                iminus1=rowSpinToFlip-1
            }
            else
            {
                iminus1=rowSpinToFlip-1
                iplus1=rowSpinToFlip+1
            }
            
            if(columnSpinToFlip == 0)
            {
                jminus1=spinArrayColumns-1
                jplus1=columnSpinToFlip+1
            }
            else if(columnSpinToFlip == (spinArrayColumns-1))
            {
                jplus1=0
                jminus1=columnSpinToFlip-1
            }
            else
            {
                jminus1=columnSpinToFlip-1
                jplus1=columnSpinToFlip+1
            }
            
            i = rowSpinToFlip
            j = columnSpinToFlip
            
            /******** Calculate The Change In Energy *****************************/
            
            energyAfterSpinFlip = energyPriorToSpinFlip + 2 * (spinArray[i+j*spinArrayColumns]) * ( (spinArray[iminus1+j*spinArrayColumns])
                + (spinArray[iplus1+j*spinArrayColumns]) + (spinArray[i+jminus1*spinArrayColumns]) + (spinArray[i+jplus1*spinArrayColumns]))
            
            /**********************************************************************************************************/
            /******** We do not accept each state as we would oversample the high probability states     **************/
            /******** In order to make the histogram flat, we must oversample the low probability states **************/
            /******** We do this by accepting states with probability = 1/g(E)                           **************/
            /******** The Histogram will be flat, equally sampling energy states when the probablitliy   **************/
            /******** 1/g(E) * g(E) = 1. Effectively, this finds 1/g(E)                                  **************/
            /**********************************************************************************************************/
            
            /******* Check For Low Probability State ****************/
            
            let theIndexForEnergyAfterSpinFlip = indexForEnergy(absoluteEnergy: energyAfterSpinFlip, totalNumberOfSpins: numberOfSpins)
            let theIndexForEnergyBeforeSpinFlip = indexForEnergy(absoluteEnergy: energyPriorToSpinFlip, totalNumberOfSpins: numberOfSpins)
            
            if( (lnDOS[theIndexForEnergyAfterSpinFlip]) <= (lnDOS[theIndexForEnergyBeforeSpinFlip]))
            {
                /**************  It is a low probability state so accept   ****************/
                energyPriorToSpinFlip = energyAfterSpinFlip
                
                /**************         Now Flip The Spin                  ****************/
                spinArray[i+j*spinArrayColumns] *= -1
            }
                /**************  Otherwise it is a high probability state  ****************/
            else
            {
                /*************************************************************************************************/
                /**************                                                              *********************/
                /**************  Accept the state only with probablilty = (1/DosNew)*DosOld  *********************/
                /**************                                                              *********************/
                /**************           g(Eold)/g(Enew) = exp(ln(g(Eold)/g(Enew))          *********************/
                /**************           g(Eold)/g(Enew) = exp(ln(g(Eold))-ln(g(Enew)))     *********************/
                /**************                                                              *********************/
                /*************************************************************************************************/

                 
                probabilityCondition = exp((lnDOS[theIndexForEnergyBeforeSpinFlip])-(lnDOS[theIndexForEnergyAfterSpinFlip]))
                
                /************** Get a random double and compare to probabilityCondition If random > Prob reject, else accept **********/
                if(Double.random(in: 0...1) <= probabilityCondition)
                {
                    /**************               Accept                       ****************/
                    energyPriorToSpinFlip = energyAfterSpinFlip
                    
                    /**************         Now Flip The Spin                  ****************/
                    spinArray[i+j*spinArrayColumns] *= -1
                }
                else
                {
                    /**************     Reject (Retain Old Spin Condition As New Spin Condition     ****************/
                    //energyPriorToSpinFlip = energyPriorToSpinFlip
                    
                    /**************          Do Not Flip Spin                  *****************/
                    
                }
            
            }
            
            /********************       The Energy Of The Current State After the Probability Check Is     ********************/
            newEnergy = energyPriorToSpinFlip;
            
            /**********************************************************************************************************/
            /******** Now we have to update the DOS, g(E), we multiply the old DOS at the newEnergy      **************/
            /********           by the weighting factor, f, to get the new DOS                           **************/
            /********                          gnew(Enew) = f * gold(Enew)                               **************/
            /********    HOWEVER, we are storing lnDOS to avoid overflow errors so we must use the ln    **************/
            /********                        equality:    ln(A*B) = ln(A) + ln(B)                        **************/
            /********                                                                                    **************/
            /********                       ln(f*DOS) = lnDOS + ln(f)    ln(f) = log(f) in c             **************/
            /**********************************************************************************************************/
            
            let indexForNewEnergy = indexForEnergy(absoluteEnergy: newEnergy, totalNumberOfSpins: numberOfSpins)

            lnDOS[indexForNewEnergy] += log(f)
            
            /**********************************************************************************************************/
            /********                        Now we have to update the Histogram                         **************/
            /**********************************************************************************************************/
            
            histogramOfEnergyStates[indexForNewEnergy] += 1
            histogramToPlot[indexForNewEnergy] += 1
            
            /****************             Test For End Condition  Histogram Flatness                 ******************/
            
            if(iterationCounter%50000==0)                                    //Check the flatness of the histogram every 50000 iterations
            {
                
                maximumValueOfHistogram = histogramOfEnergyStates.max()!                                       //Initilize the upper bound of the histogram to zero to which the next value is compared
                
               // minimumValueOfHistogram = histogramOfEnergyStates.min()!
                minimumValueOfHistogram = histogramOfEnergyStates.filter{ $0 > 0 }.min()!
                //initilize the lower bound of the histogram to an arbitrarily big number to which the next value is compared
                
                if minimumValueOfHistogram == 0 {
                    
                    hasZeros = true
                }
                else {
                    
                    hasZeros = false
                }

               // if(!hasZeros)
                //{
                
                /****************             Calculate Histogram Flatness Check 80 % Flatness              ******************/
                
                    heightOfHistogram = Double(abs(maximumValueOfHistogram - minimumValueOfHistogram))        //height of the histogram is the difference between the biggest and lowest values
                    sumOfHistogram = Double(maximumValueOfHistogram + minimumValueOfHistogram)        //The sum of the histogram is the sum of the biggest and lowest value
                
                if( (heightOfHistogram/sumOfHistogram) < 0.2 )                                //Flatness condition
                {
                    print("%d\t%le\n", iterationCounter, f)                        //outputs to screen the iteration number and the correction factor

                    f = sqrt(f)                                            //updates the correction factor
                    
                    /****************** Print Energy, Histogram, lnDOS ********************/
                    
                    wangLandauOutputText += "Energy\tHistogram\tlnDos\tDOS\n"
                    
                    for i in 0 ... numberOfSpins
                    {
                        
                        /************************************************************************************/
                        /**************                                                        *****************/
                        /**************                Apply The Normalization Condition       *****************/
                        /**************       g(Emin) = 2, Only 2 states with Energy = Emin    *****************/
                        /**************            Normalization Constant = g(Emin Calc)/2     *****************/
                        /**************                Final g(Ei) = g(Ei)/Constant            *****************/
                        /**************                g(Ei) = g(Ei)/[g(Emin Calc)/2]          *****************/
                        /**************                                                     *****************/
                        /**************       ln[g(Ei)] = ln[g(Ei)] - ln[g(E0)] + ln[2]     *****************/
                        /**************                                                     *****************/
                        /************************************************************************************/
                        
                        if(histogramOfEnergyStates[i] != 0)
                        {
                            
                            let energy = energyForIndex(energyIndex: i, totalNumberOfSpins:numberOfSpins)
                            let normLnDos = lnDOS[i]-lnDOS[0]+log(2)
                            let expNormLnDos = exp(lnDOS[i]-lnDOS[0]+log(2))
                            
                            wangLandauOutputText += String(format: "%d\t%d\t%lf\t%10.7g\n", energy, histogramOfEnergyStates[i], (normLnDos), expNormLnDos)
                            
                        }
                        
                    
                    //    *(lnDOS+i) = (*(lnDOS+i)-*(lnDOS)+log(2));
                    
                    }
                    wangLandauOutputText += "\n"
                    
                    ///reset histogram for next iteration
                    
                    for i in 0...numberOfSpins
                    {
                        histogramOfEnergyStates[i] = 0
                    }
                    hasZeros = true
                }
                    
                
               // }
                
            }
            
        }
        
        /*********** This Completes The Determination of the lnDOS *************************/
        
        /***********************************************************************************/
        /***********                                               *************************/
        /***********  Now That The DOS Has Been Determined We Can  *************************/
        /***********  Use It To Determine The Thermodynamic        *************************/
        /***********  Properties, Magnitism, Heat Capacity,        *************************/
        /***********  and Internal Energy                          *************************/
        /***********                                               *************************/
        /***********************************************************************************/
        
        
        /***********************************************************************************/
        /***********                                               *************************/
        /***********            Calculate Entropy From DOS         *************************/
        /***********                                               *************************/
        /***********             S = kb * T * ln(g(E))             *************************/
        /***********                Leave Off T Here               *************************/
        /***********                                               *************************/
        /***********************************************************************************/
        
        
        for i in 0..<numberOfSpins
        {
            entropy[i] = kb * (lnDOS[i])
        }

        /***Plot Density of States and Histogram */
        
        for i in 0..<numberOfSpins {

            histogramData.append(DensityOfStatesHistogram(energies: myEnergy.possibleEnergyArray[i], densityOfStates: lnDOS[i], histogram: histogramToPlot[i]))
        }
        
        histogramToPlot = []
    }
    
    func initializeMatrices(){
        
        /************** Initialize Matrices    ***********************************/
        spinArrayRows = dimension
        spinArrayColumns = dimension
        numberOfSpins = spinArrayRows*spinArrayColumns
        
        spinArray = Array(repeating: 1, count: numberOfSpins)
        lnDOS = Array(repeating: 0.0, count: numberOfSpins+1)
        entropy = Array(repeating: 0.0, count: numberOfSpins+1)
        histogramToPlot = Array(repeating: 0, count: numberOfSpins+1)
        histogramOfEnergyStates = Array(repeating: 0, count: numberOfSpins+1)
        /************* calloc initializes the values to 0 but the log(1) = 0 so this is equivalent to setting the DOS to 1, ie. g(E)=1 at all energies ************/
    }
    
    func coldStart(){
        
        /************* Initialize The System With All Spins Aligned (Cold Start) ***************/
        
        for i in 0 ..< spinArrayRows{
            
            for j in 0 ..< spinArrayColumns {
                
                spinArray[i+j*spinArrayColumns] = 1
            }
        
        }

        /************ With All Spins Aligns The Energy Of The System is -2*numberOfStates, Assuming that spins are +/- 1 and not +/- 1/2 *********************/
        
        energyPriorToSpinFlip = -2 * numberOfSpins
        
        /*********** Ends Initialization of Aligned Spin State (Cold Start)    *****************************/
        
    }
    
    /************************************************************************************************************************/
    /************************************************************************************************************************/
    /******************* Calculates The Absolute Energy Of From The Index Of The Energy Array  ******************************/
    /******************* In 2D,    Energy states are -2N, -2N+4, -2N+8, 0, 4, 2N-8, 2N-4, 2 N  ******************************/
    /******************* Assumes that spins are +/- 1 and not +/- 1/2                          ******************************/
    /*******************                                                                       ******************************/
    /******************* energyIndex = (absoluteEnergy + 2.0*totalNumberOfSpins)/4.0           ******************************/
    /*******************                                                                       ******************************/
    /******************* absoluteEnergy = 4.0*energyIndex - 2.0*totalNumberOfSpins             ******************************/
    /************************************************************************************************************************/
    /************************************************************************************************************************/
    func energyForIndex(energyIndex: Int, totalNumberOfSpins: Int) -> Int {
 
        var absoluteEnergy :Int = 0
        absoluteEnergy = 4 * energyIndex - 2 * totalNumberOfSpins
        myEnergy.possibleEnergyArray.append(absoluteEnergy)
        
        return(absoluteEnergy)
        
        
    }
    
    /************************************************************************************************************************/
    /************************************************************************************************************************/
    /******************* Calculates The Absolute Energy Of From The Index Of The Energy Array  ******************************/
    /******************* In 2D,    Energy states are -2N, -2N+4, -2N+8, 0, 4, 2N-8, 2N-4, 2 N  ******************************/
    /******************* Assumes that spins are +/- 1 and not +/- 1/2                          ******************************/
    /*******************                                                                       ******************************/
    /******************* energyIndex = (absoluteEnergy + 2.0*totalNumberOfSpins)/4.0           ******************************/
    /*******************                                                                       ******************************/
    /******************* absoluteEnergy = 4.0*energyIndex - 2.0*totalNumberOfSpins             ******************************/
    /************************************************************************************************************************/
    /************************************************************************************************************************/
    
    func indexForEnergy(absoluteEnergy: Int, totalNumberOfSpins: Int) -> Int {
        
        var energyIndex :Int = 0
        energyIndex = (absoluteEnergy + 2 * totalNumberOfSpins)/4
        
        return(energyIndex)
        
        
    }
    
//    func calculateHistogramData () {
//        let N = Double(Num)!
//        let totalSpins = pow(N, 2.0)
//        let spinTotal = Int(totalSpins)
//
//        for i in 0...spinTotal {
//            // 0.0 because ln(1) = 0 and in ln form
//            myDensityOfStates.histogram.append(0.0)
//        }
//        //  print("Histogram: ")
//        //  print(myDensityOfStates.histogram)
//    }
    
    
//    func something () {
//    print("While Loop is Over!")
//        var lnDOSForPlot = myDensityOfStates.lnDensityOfStates
//        var BobArray :[Double] = []
//        for i in 0..<(myDensityOfStates.lnDensityOfStates.count) {
//            BobArray.append(lnDOSForPlot[i] - lnDOSForPlot[0] + log(2))
//// exp(lnDOSForPlot[i] - lnDOSForPlot[0] + log(2))
//// probably 24 or 25
//            if BobArray[i] < 0.0 {
//                BobArray[i] = 0.0
//            }
//        }
//        for i in 0...(myEnergy.possibleEnergyArray.count - 1) {
//
//            histogramData.append(DensityOfStatesHistogram(energies: myEnergy.possibleEnergyArray[i], densityOfStates: BobArray[i], histogram: myDensityOfStates.histogram[i]))
//        }
//        print("Bob")
//    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
