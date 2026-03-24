import { motion } from 'framer-motion';

const features = [
  {
    title: "Brand Authority",
    description: "A concise, universally recognizable identity built for global scale and massive market visibility."
  },
  {
    title: "Market Alignment",
    description: "Precision-engineered for on-chain wagering, fast-settlement forecasting, and transaction flow."
  },
  {
    title: "Premium Transferability",
    description: "Establishes immediate operational gravity and high execution leverage upon acquisition."
  }
];

export default function WhyWirebet() {
  return (
    <section className="py-32 md:py-40 px-6 bg-background text-center flex flex-col items-center">
      <div className="max-w-6xl mx-auto w-full">
        <motion.div 
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: "-100px" }}
          transition={{ duration: 0.8 }}
          className="mb-24 flex flex-col items-center"
        >
          <div className="w-[1px] h-16 bg-white/40 mb-10" />
          <h2 className="text-3xl md:text-5xl font-display font-medium tracking-wide text-white">Strategic Advantage</h2>
        </motion.div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 lg:gap-8">
          {features.map((feature, idx) => (
            <motion.div 
              key={idx}
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true, margin: "-100px" }}
              transition={{ duration: 0.8, delay: idx * 0.1 }}
              className="bg-surface border border-border p-12 hover:border-white/30 hover:shadow-2xl transition-all duration-500 flex flex-col items-start text-left relative overflow-hidden group"
            >
              <div className="absolute top-0 left-0 w-full h-1 bg-white/5 group-hover:bg-white/20 transition-colors" />
              <span className="text-xs font-mono text-tertiaryText mb-6 group-hover:text-secondaryText transition-colors">{(idx + 1).toString().padStart(2, '0')} //</span>
              <h3 className="text-xl md:text-2xl font-display font-medium text-white mb-4 tracking-wide group-hover:text-white">{feature.title}</h3>
              <p className="text-secondaryText font-normal leading-relaxed tracking-wide text-base">{feature.description}</p>
            </motion.div>
          ))}
        </div>
      </div>
    </section>
  );
}
