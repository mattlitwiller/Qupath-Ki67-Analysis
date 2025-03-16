/**
 * Script to set custom stain vector obtained experimentally.
 * Obtained from auto 0.01, 10, 1 BUT then modified DAB vector to match a rectangle in the DABonly.ndpi file. Separates stains very well.
 * Also allows the user to enter a custom new stain vector if desired
 * 
 * @Author Matthew Litwiller
 */

try {
    //str = '{"Name" : "H-DAB estimated", "Stain 1" : "Hematoxylin", "Values 1" : "' + [0.636, 0.715, 0.289] + '", "Stain 2" : "DAB", "Values 2" : "' + [0.408, 0.599, 0.689] + '", "Background" : "' + [233, 232, 240] + '"}'
    if(args.size() > 0) {
        def vectorStrings = args.toString().replaceAll("[\\[\\]]", "").split(";")
        def vectors = vectorStrings.collect { it.split(",").collect { it.trim().toDouble() } }
        setImageType(getCurrentImageData().ImageType.BRIGHTFIELD_H_DAB)
        str = '{"Name" : "H-DAB estimated", "Stain 1" : "Hematoxylin", "Values 1" : "' + vectors[0] + '", "Stain 2" : "DAB", "Values 2" : "' + vectors[1] + '", "Background" : "' + vectors[2] + '"}'
        setColorDeconvolutionStains(str)
    }else{
        setImageType(getCurrentImageData().ImageType.BRIGHTFIELD_H_DAB)
        str = '{"Name" : "H-DAB estimated", "Stain 1" : "Hematoxylin", "Values 1" : "' + [0.636, 0.715, 0.289] + '", "Stain 2" : "DAB", "Values 2" : "' + [0.438, 0.65, 0.621] + '", "Background" : "' + [233, 232, 240] + '"}'
        setColorDeconvolutionStains(str)
    }
}catch (Exception e){
    //propagate error since it otherwise would not be propagated
    e.printStackTrace()
    System.exit(1)
}







